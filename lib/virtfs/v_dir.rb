module VirtFS
  class VDir
    include DirInstanceDelegate

    VfsRealDir.constants.each { |cn| const_set(cn, VfsRealDir.const_get(cn)) }

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
      def [](glob_pattern)
        glob(glob_pattern, 0)
      end

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

      def chroot(dir)
        VirtFS.dir_chroot(dir)
        0
      end

      def delete(dir)
        VirtFS.fs_lookup_call(dir, true) { |p| dir_delete(p) }
        0
      end
      alias_method :unlink, :delete
      alias_method :rmdir, :delete

      def entries(dir)
        VirtFS.fs_lookup_call(dir) { |p| dir_entries(p) }
      end

      def exist?(dir)
        begin
          fs, p = VirtFS.path_lookup(dir)
        rescue Errno::ENOENT
          return false
        end
        VirtFS.fs_call(fs) { dir_exist?(p) }
      end
      alias_method :exists?, :exist?

      def foreach(dir, &block)
        VirtFS.fs_lookup_call(dir) { |p| dir_foreach(p, &block) }
      end

      def getwd
        VirtFS.dir_getwd
      end
      alias_method :pwd, :getwd

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

      def mkdir(dir, permissions = 0700)
        VirtFS.fs_lookup_call(dir, true) { |p| dir_mkdir(p, permissions) }
        0
      end

      #
      # Instantiate directory instance.
      #

      def new(dir, hash_args = {})
        fs, p = VirtFS.path_lookup(dir)
        fs_obj = VirtFS.fs_call(fs) { dir_new(p, hash_args, dir, VDir.getwd) }
        fs_obj = ThinDirDelegator.new(fs_obj, dir, p, hash_args) if fs.thin_interface?
        obj = allocate
        obj.send(:initialize, fs_obj, dir)
        obj
      end

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
