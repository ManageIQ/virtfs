module VirtFS
  # VirtFS Dir representation - implements the core Ruby Dir methods, dispatching
  # to underlying mounted VirtFS filesystems
  class VDir # rubocop:disable ClassLength
    attr_accessor :fs_mod_obj

    include DirInstanceDelegate

    VfsRealDir.constants.each { |cn| const_set(cn, VfsRealDir.const_get(cn)) }

    # VDir initializer
    #
    # @param dir_obj [VirtFS::FS::Dir] handle to filesystem specific dir obj
    # @param path [String] path at which the dir resides
    #
    def initialize(dir_obj, path)
      @open_path = path
      __setobj__(dir_obj)
    end

    #
    # Some methods need to return the Dir object. Methods in the delegator
    # object can't do that, so we intercept them and do it here.
    #

    def each
      return self if (rv = super) == __getobj__
      rv
    end

    # @return [String] path which dir resides
    def path
      @open_path
    end
    alias_method :to_path, :path

    def rewind
      super
      self
    end

    def seek(*args)
      super
      self
    end

    # Class methods
    class << self
      # Return dir entries matching the specified glob pattern
      #
      # @param glob_pattern [String,Regex] dir entry pattern to match
      # @see Dir.[]
      #
      def [](glob_pattern)
        glob(glob_pattern, 0)
      end

      # Change working directory to specified dir
      #
      # @param dir [String] path to change working directory to
      # @see Dir.chdir
      #
      def chdir(dir = nil)
        dir ||= VfsRealDir.home
        raise SystemCallError.new(dir, Errno::ENOENT::Errno) unless exist?(dir)
        if block_given?
          pwd = getwd
          begin
            VirtFS.dir_chdir(dir)
            return yield(getwd)
          ensure
            VirtFS.dir_chdir(pwd)
          end
        end
        VirtFS.dir_chdir(dir)
        0
      end

      # Change root dir to specified dir
      #
      # @param dir [String] dir to change root dir to
      # @see Dir.chroot
      #
      def chroot(dir)
        VirtFS.dir_chroot(dir)
        0
      end

      # Delete specified dir
      #
      # @param dir [String] dir to delete
      # @see Dir.delete
      #
      def delete(dir)
        VirtFS.fs_lookup_call(dir, true) { |p| dir_delete(p) }
        0
      end
      alias_method :unlink, :delete
      alias_method :rmdir, :delete

      # Return array containing entries in specified dir
      #
      # @param dir [String] dir which to enumerate entries
      #
      # @return [Array<DirEntry>]  array of dir entry instances
      #
      # @see Dir.entries
      #
      def entries(dir)
        VirtFS.fs_lookup_call(dir) { |p| dir_entries(p) }
      end

      # Return bool indicating if specified dir exists
      #
      # @param dir [String] directory path to verify
      # @return [Boolean] indicating if dir exists
      #
      def exist?(dir)
        begin
          fs, p = VirtFS.path_lookup(dir)
        rescue Errno::ENOENT
          return false
        end
        VirtFS.fs_call(fs) { dir_exist?(p) }
      end
      alias_method :exists?, :exist?

      # Invoke block for each entry in dir
      #
      # @param dir [String] dir which to lookup entries
      # @yield block to invoke
      def foreach(dir, &block)
        VirtFS.fs_lookup_call(dir) { |p| dir_foreach(p, &block) }
      end

      # @return [String] current working directory
      def getwd
        VirtFS.dir_getwd
      end
      alias_method :pwd, :getwd

      # Return directory entries matching specified glob pattern
      #
      # @param glob_pattern [String] pattern to match
      # @param flags [Integer] file match flags
      # @yield block invoked with each match if specified
      #
      # @see VfsRealFile.fnmatch
      # @see FindClassMethods#dir_and_glob which does most of the work regarding globbing
      # @see FindClassMethods#find which retrieves stats information & dir entries for found files
      #
      def glob(glob_pattern, flags = 0)
        search_path, specified_path, glob = VirtFS.dir_and_glob(glob_pattern)

        unless exist?(search_path)
          return [] unless block_given?
          return false
        end

        ra = [] unless block_given?
        VirtFS.find(search_path, VirtFS.glob_depth(glob)) do |p|
          next if p == search_path

          if search_path == VfsRealFile::SEPARATOR
            p.sub!(VfsRealFile::SEPARATOR, "")
          else
            p.sub!("#{search_path}#{VfsRealFile::SEPARATOR}", "")
          end

          next if p == ""
          next unless VfsRealFile.fnmatch(glob, p, flags)

          p = VfsRealFile.join(specified_path, p) if specified_path
          block_given? ? yield(p) : ra << p
        end
        block_given? ? false : ra.sort_by(&:downcase)
      end

      def home(*args)
        VfsRealDir.home(*args)
      end

      # Make new dir at specified path
      #
      # @param dir [String] path to create
      # @param permissions [Integer] initial permission to assign to dir
      #
      def mkdir(dir, permissions = 0700)
        VirtFS.fs_lookup_call(dir, true) { |p| dir_mkdir(p, permissions) }
        0
      end

      # Instantiate new directory instance.
      #
      # @param dir [String] path to dir to instantiate
      # @param hash_args [Hash] args to use when creating Dir instance
      #
      # @see VirtFS.fs_call
      # @see ThinDirDelegator
      #
      def new(dir, hash_args = {})
        fs, p = VirtFS.path_lookup(dir)
        fs_obj = VirtFS.fs_call(fs) { dir_new(p, hash_args, dir, VDir.getwd) }

        obj = allocate
        if fs.thin_interface?
          obj.send(:initialize, ThinDirDelegator.new(fs_obj, dir, p, hash_args), dir)
        else
          obj.send(:initialize, fs_obj, dir)
        end

        # fs_mod_obj always points to the fs module's file object
        # for use by fs-specific extension modules
        obj.fs_mod_obj = fs_obj
        obj.extend(fs_obj.extension_module) if fs_obj.respond_to?(:extension_module) # fs-specific extension module
        obj
      end

      # Open specified existing dir and invoke block with it before closing
      #
      # @param dir [String] path to dir to instantiate
      # @param hash_args [Hash] args to use when creating Dir instance
      #
      # @yield the directory instance
      # @see .new
      #
      def open(dir, hash_args = {})
        dir_obj = new(dir, hash_args)
        return dir_obj unless block_given?
        begin
          return yield(dir_obj)
        ensure
          dir_obj.close
        end
      end
    end # class methods
  end
end
