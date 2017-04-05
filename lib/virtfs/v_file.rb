module VirtFS
  # VirtFS File representation - implements the core Ruby File methods, dispatching
  # to underlying mounted VirtFS filesystems
  #
  class VFile < VIO # rubocop:disable ClassLength
    attr_accessor :fs_mod_obj

    include FileInstanceDelegate

    VfsRealFile.constants.each { |cn| const_set(cn, VfsRealFile.const_get(cn)) }

    # VFile initializer
    #
    # @param file_obj [VirtFS::FS::File] handle to filesystem specific file obj
    # @param path [String] path at which the file resides
    #
    def initialize(file_obj, path)
      @open_path = path
      __setobj__(file_obj)
    end

    #
    # Some methods need to return the File object. Methods in the delegator
    # object can't do that, so we intercept them and do it here.
    #

    def <<(obj)
      super
      self
    end

    def binmode
      super
      self
    end

    def each(*args)
      return self if (rv = super) == __getobj__
      rv
    end

    def each_byte
      return self if (rv = super) == __getobj__
      rv
    end

    def each_char
      return self if (rv = super) == __getobj__
      rv
    end

    def each_codepoint
      return self if (rv = super) == __getobj__
      rv
    end

    def flush
      return self if (rv = super) == __getobj__
      rv
    end

    # @return [String] path which dir resides
    def path
      @open_path
    end
    alias_method :to_path, :path

    # Reopens file with the given args
    def reopen(*args)
      new_path = nil
      if !args[0].respond_to?(:to_str) && args[0].respond_to?(:__getobj__)
        # Given an IO object.
        to_obj = args[0]
        args = [to_obj.__getobj__]
        new_path = to_obj.path
      end
      new_obj = __getobj__.reopen(*args)
      __setobj__(new_obj)
      @open_path = new_path || new_obj.path
      self
    end

    def set_encoding(*args)
      super
      self
    end

    def to_io
      self
    end

    def min_read_buf_sz=(val)
      __getobj__.send(:min_read_buf_sz=, val)
    rescue
      # ignore
    end
    private :min_read_buf_sz=

    # Class methods
    class << self
      # @return absolute path of file (across mounted filesystems)
      def absolute_path(f, dirstring = nil)
        dir = dirstring || VirtFS.dir_getwd
        VfsRealFile.absolute_path(f, dir)
      end

      # @return [Time] access time of the file
      def atime(f)
        VirtFS.fs_lookup_call(f) { |p| file_atime(p) }
      end

      # @return [String] base name of the file
      def basename(*args)
        VfsRealFile.basename(*args)
      end

      # @return [Boolean] indicating if file is a block device
      def blockdev?(f)
        VirtFS.fs_lookup_call(f) { |p| file_blockdev?(p) }
      end

      # @return [Boolean] indicating if file is a char device
      def chardev?(f)
        VirtFS.fs_lookup_call(f) { |p| file_chardev?(p) }
      end

      # Change File ACLs
      #
      # @param permission [Integer] new acl to assign to file(s)
      def chmod(permission, *files)
        nfp = 0
        files.each do |f|
          nfp += VirtFS.fs_lookup_call(f) { |p| file_chmod(permission, p) }
        end
        nfp
      end

      # Change ownership / group ownership of file
      #
      # @param owner [Integer,String] new owner of the file(s)
      # @param group [Integer,String] new group owner of the file(s)
      def chown(owner, group, *files)
        owner = owner.to_int
        group = group.to_int
        nfp = 0
        files.each do |f|
          nfp += VirtFS.fs_lookup_call(f) { |p| file_chown(owner, group, p) }
        end
        nfp
      end

      # @return ]Time] change time of time
      def ctime(f)
        VirtFS.fs_lookup_call(f) { |p| file_ctime(p) }
      end

      # Delete specified files
      def delete(*files)
        nfp = 0
        files.each do |f|
          nfp += VirtFS.fs_lookup_call(f, false, false) { |p| file_delete(p) }
        end
        nfp
      end
      alias_method :unlink, :delete

      # @return [Boolean] indiciating if file is a directory
      def directory?(f)
        VirtFS.fs_lookup_call(f) { |p| file_directory?(p) }
      end

      # @return [String] containg file directory name
      def dirname(*args)
        VfsRealFile.dirname(*args)
      end

      # @return [Boolean] indiciating if file is executable
      def executable?(f)
        VirtFS.fs_lookup_call(f) { |p| file_executable?(p) }
      end

      # @return [Boolean] indiciating if file is executable and real
      def executable_real?(f)
        VirtFS.fs_lookup_call(f) { |p| file_executable_real?(p) }
      end

      # @return [Boolean] indiciating if file exists
      def exist?(f)
        VirtFS.fs_lookup_call(f) { |p| file_exist?(p) }
      end
      alias_method :exists?, :exist?

      # @return [String] full expanded path to file
      def expand_path(f, dirstring = nil)
        dir = dirstring || VirtFS.dir_getwd
        VfsRealFile.expand_path(f, dir)
      end

      # @return [String] containg file extension name
      def extname(*args)
        VfsRealFile.extname(*args)
      end

      # @return [Boolean] indiciating if file is a regular file
      def file?(f)
        VirtFS.fs_lookup_call(f) { |p| file_file?(p) }
      end

      # @return [Array<String>] names of files matching given args
      def fnmatch(*args)
        VfsRealFile.fnmatch(*args)
      end
      alias_method :fnmatch?, :fnmatch

      # @return type of file specified
      def ftype(f)
        VirtFS.fs_lookup_call(f) { |p| file_ftype(p) }
      end

      # @return [Boolean] indicating if file is group owned
      def grpowned?(f)
        VirtFS.fs_lookup_call(f) { |p| file_grpowned?(p) }
      end

      # @return [Boolean] indicating if files are identical
      def identical?(fname1, fname2)
        fs1, p1 = VirtFS.path_lookup(fname1)
        fs2, p2 = VirtFS.path_lookup(fname2)
        return false unless fs1 == fs2
        VirtFS.fs_call(fs1) { file_identical?(p1, p2) }
      end

      # @return [String] containing joined path components
      def join(*args)
        VfsRealFile.join(*args)
      end

      # Invoke a 'lchmod' on the given files
      #
      # @param permission [Integer] new permission to assign to file(s)
      #
      def lchmod(permission, *files)
        nfp = 0
        files.each do |f|
          nfp += VirtFS.fs_lookup_call(f) { |p| file_lchmod(permission, p) }
        end
        nfp
      end

      # Invoke a 'lchown' on the given files
      #
      # @param owner [String] new owner to assign to file(s)
      # @param group [String] new group to assign to file(s)
      #
      def lchown(owner, group, *files)
        nfp = 0
        files.each do |f|
          nfp += VirtFS.fs_lookup_call(f, false, false) { |p| file_lchown(owner, group, p) }
        end
        nfp
      end

      # Create a symbol link between files
      #
      # @param oname [String] file to link to
      # @param nname [String] symbolic link to create
      #
      def link(oname, nname)
        fs1, p1 = VirtFS.path_lookup(oname)
        fs2, p2 = VirtFS.path_lookup(nname)
        raise SystemCallError, "Can't hard link between filesystems" unless fs1 == fs2 # TODO: check exception
        VirtFS.fs_call(fs1) { file_link(p1, p2) }
      end

      # @return [Stat] file stat for specified file
      def lstat(f)
        VirtFS.fs_lookup_call(f, false, false) { |p| file_lstat(p) }
      end

      # @return [Time] modification time of the specified file
      def mtime(f)
        VirtFS.fs_lookup_call(f) { |p| file_mtime(p) }
      end

      # @return [Boolean] indicating if file is owned
      def owned?(f)
        VirtFS.fs_lookup_call(f) { |p| file_owned?(p) }
      end

      # @return path to specified file object
      def path(obj)
        VfsRealFile.path(obj) # will check obj.to_path
      end

      # @return [Boolean] indicating if file is pipe
      def pipe?(f)
        VirtFS.fs_lookup_call(f) { |p| file_pipe?(p) }
      end

      # @return [Boolean] indicating if file is readable
      def readable?(f)
        VirtFS.fs_lookup_call(f) { |p| file_readable?(p) }
      end

      # @return [Boolean] indicating if file is real and readable
      def readable_real?(f)
        VirtFS.fs_lookup_call(f) { |p| file_readable_real?(p) }
      end

      # @return [String] name of file references by link
      def readlink(f)
        VirtFS.fs_lookup_call(f, false, false) { |p| file_readlink(p) }
      end

      # @return [String] real directory containing file
      def realdirpath(path, relative_to = nil) # ???
        VirtFS.expand_links(VirtFS.normalize_path(path, relative_to))
      end

      # @return [String] real path of the file
      def realpath(path, relative_to = nil) # ???
        VirtFS.expand_links(VirtFS.normalize_path(path, relative_to))
      end

      # Rename file
      #
      # @param oname [String] file to rename
      # @param nname [String] new name to assign to file
      #
      def rename(oname, nname)
        fs1, p1 = VirtFS.path_lookup(oname)
        fs2, p2 = VirtFS.path_lookup(nname)
        raise SystemCallError, "Can't rename between filesystems" unless fs1 == fs2 # TODO: check exception
        VirtFS.fs_call(fs1) { file_rename(p1, p2) }
      end

      # @return [Boolean] indicating if file GID is set
      def setgid?(f)
        VirtFS.fs_lookup_call(f) { |p| file_setgid?(p) }
      end

      # @return [Boolean] indicating if file UID is set
      def setuid?(f)
        VirtFS.fs_lookup_call(f) { |p| file_setuid?(p) }
      end

      # @return [Integer] size of the file in bytes
      def size(f)
        VirtFS.fs_lookup_call(f) { |p| file_size(p) }
      end

      # @return [Integer,nil] same as #size but return nil if empty
      def size?(f)
        sz = size(f)
        return nil if sz == 0
        sz
      end

      # @return [Boolean] indicating if file is a socket
      def socket?(f)
        VirtFS.fs_lookup_call(f) { |p| file_socket?(p) }
      end

      # @return [Array<String>] split file path
      def split(f)
        VfsRealFile.split(f)
      end

      # @return [Stat] file stat correspond to file
      def stat(f)
        VirtFS.fs_lookup_call(f) { |p| file_stat(p) }
      end

      # @return [Boolean] indicating if file is sticky
      def sticky?(f)
        VirtFS.fs_lookup_call(f) { |p| file_sticky?(p) }
      end

      # Create new symlink to file
      #
      # @param oname [String] file to link to
      # @param nname [String] symbollic link to create
      #
      def symlink(oname, nname)
        #
        # oname is the path to the original file in the global FS namespace.
        # It is not modified and used as the link target.
        #
        VirtFS.fs_lookup_call(nname) { |p| file_symlink(oname, p) }
      end

      # @return [Boolean] indicating if file is symlink
      def symlink?(f)
        VirtFS.fs_lookup_call(f, false, false) { |p| file_symlink?(p) }
      end

      # Truncate file to the specified len
      #
      # @param f [String] file to truncate
      # @param len [Integer] length to truncate file to (in bytes)
      def truncate(f, len)
        VirtFS.fs_lookup_call(f) { |p| file_truncate(p, len) }
      end

      # @return [Integer] umake of file
      def umask(*args)
        VfsRealFile.umask(*args)
      end

      # Update file time
      #
      # @param atime [Time] new access time to assign to file(s)
      # @param mtime [Time] new modification time to assign to file(s)
      def utime(atime, mtime, *files)
        nfp = 0
        files.each do |f|
          nfp += VirtFS.fs_lookup_call(f) { |p| file_utime(atime, mtime, p) }
        end
        nfp
      end

      # @return [Boolean] indicating if file is world readable
      def world_readable?(f)
        VirtFS.fs_lookup_call(f) { |p| file_world_readable?(p) }
      end

      # @return [Boolean] indicating if file is world writable
      def world_writable?(f)
        VirtFS.fs_lookup_call(f) { |p| file_world_writable?(p) }
      end

      # @return [Boolean] indicating if file is writable
      def writable?(f)
        VirtFS.fs_lookup_call(f) { |p| file_writable?(p) }
      end

      # @return [Boolean] indicating if file is writable and real
      def writable_real?(f)
        VirtFS.fs_lookup_call(f) { |p| file_writable_real?(p) }
      end

      def zero?(f)
        fs, p = VirtFS.path_lookup(f)
        begin
          VirtFS.fs_call(fs) { file_chardev?(p) }
          return fs.file_size(p) == 0
        rescue Errno::ENOENT
          return false
        end
      end

      # Instantiate new file instance.
      #
      # @param file_id [String] file identifier (usually path)
      # @param args args to forward to file initializer
      def new(file_id, *args) # rubocop:disable AbcSize
        if file_id.respond_to?(:to_int)
          fs_obj = VfsRealIO.new(file_id, *args)
        else
          parsed_args = FileModesAndOptions.new(*args)
          fs, p = VirtFS.path_lookup(file_id, false, false)
          fs_obj = VirtFS.fs_call(fs) { file_new(p, parsed_args, file_id, VDir.getwd) }
        end

        obj = allocate
        if fs.thin_interface?
          obj.send(:initialize, ThinFileDelegator.new(fs_obj, file_id, p, parsed_args), file_id)
        else
          obj.send(:initialize, fs_obj, file_id)
        end

        # fs_mod_obj always points to the fs module's file object
        # for use by fs-specific extension modules
        obj.fs_mod_obj = fs_obj
        obj.extend(fs_obj.extension_module) if fs_obj.respond_to?(:extension_module) # fs-specific extension module
        obj
      end
    end # class methods
  end
end
