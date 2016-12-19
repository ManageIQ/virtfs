module VirtFS
  #
  # Top-level File class methods implemented here,
  # using VirtFS module methods as needed.
  #
  # Instances delegate to FS type-specific object.
  #
  class VFile < VIO
    include FileInstanceDelegate

    VfsRealFile.constants.each { |cn| const_set(cn, VfsRealFile.const_get(cn)) }

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

    def path
      @open_path
    end
    alias_method :to_path, :path

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
      def absolute_path(f, dirstring = nil)
        dir = dirstring || VirtFS.dir_getwd
        VfsRealFile.absolute_path(f, dir)
      end

      def atime(f)
        VirtFS.fs_lookup_call(f) { |p| file_atime(p) }
      end

      def basename(*args)
        VfsRealFile.basename(*args)
      end

      def blockdev?(f)
        VirtFS.fs_lookup_call(f) { |p| file_blockdev?(p) }
      end

      def chardev?(f)
        VirtFS.fs_lookup_call(f) { |p| file_chardev?(p) }
      end

      def chmod(permission, *files)
        nfp = 0
        files.each do |f|
          nfp += VirtFS.fs_lookup_call(f) { |p| file_chmod(permission, p) }
        end
        nfp
      end

      def chown(owner, group, *files)
        owner = owner.to_int
        group = group.to_int
        nfp = 0
        files.each do |f|
          nfp += VirtFS.fs_lookup_call(f) { |p| file_chown(owner, group, p) }
        end
        nfp
      end

      def ctime(f)
        VirtFS.fs_lookup_call(f) { |p| file_ctime(p) }
      end

      def delete(*files)
        nfp = 0
        files.each do |f|
          nfp += VirtFS.fs_lookup_call(f, false, false) { |p| file_delete(p) }
        end
        nfp
      end
      alias_method :unlink, :delete

      def directory?(f)
        VirtFS.fs_lookup_call(f) { |p| file_directory?(p) }
      end

      def dirname(*args)
        VfsRealFile.dirname(*args)
      end

      def executable?(f)
        VirtFS.fs_lookup_call(f) { |p| file_executable?(p) }
      end

      def executable_real?(f)
        VirtFS.fs_lookup_call(f) { |p| file_executable_real?(p) }
      end

      def exist?(f)
        VirtFS.fs_lookup_call(f) { |p| file_exist?(p) }
      end
      alias_method :exists?, :exist?

      def expand_path(f, dirstring = nil)
        dir = dirstring || VirtFS.dir_getwd
        VfsRealFile.expand_path(f, dir)
      end

      def extname(*args)
        VfsRealFile.extname(*args)
      end

      def file?(f)
        VirtFS.fs_lookup_call(f) { |p| file_file?(p) }
      end

      def fnmatch(*args)
        VfsRealFile.fnmatch(*args)
      end
      alias_method :fnmatch?, :fnmatch

      def ftype(f)
        VirtFS.fs_lookup_call(f) { |p| file_ftype(p) }
      end

      def grpowned?(f)
        VirtFS.fs_lookup_call(f) { |p| file_grpowned?(p) }
      end

      def identical?(fname1, fname2)
        fs1, p1 = VirtFS.path_lookup(fname1)
        fs2, p2 = VirtFS.path_lookup(fname2)
        return false unless fs1 == fs2
        VirtFS.fs_call(fs1) { file_identical?(p1, p2) }
      end

      def join(*args)
        VfsRealFile.join(*args)
      end

      def lchmod(permission, *files)
        nfp = 0
        files.each do |f|
          nfp += VirtFS.fs_lookup_call(f) { |p| file_lchmod(permission, p) }
        end
        nfp
      end

      def lchown(owner, group, *files)
        nfp = 0
        files.each do |f|
          nfp += VirtFS.fs_lookup_call(f, false, false) { |p| file_lchown(owner, group, p) }
        end
        nfp
      end

      def link(oname, nname)
        fs1, p1 = VirtFS.path_lookup(oname)
        fs2, p2 = VirtFS.path_lookup(nname)
        raise SystemCallError, "Can't hard link between filesystems" unless fs1 == fs2 # TODO: check exception
        VirtFS.fs_call(fs1) { file_link(p1, p2) }
      end

      def lstat(f)
        VirtFS.fs_lookup_call(f, false, false) { |p| file_lstat(p) }
      end

      def mtime(f)
        VirtFS.fs_lookup_call(f) { |p| file_mtime(p) }
      end

      def owned?(f)
        VirtFS.fs_lookup_call(f) { |p| file_owned?(p) }
      end

      def path(obj)
        VfsRealFile.path(obj) # will check obj.to_path
      end

      def pipe?(f)
        VirtFS.fs_lookup_call(f) { |p| file_pipe?(p) }
      end

      def readable?(f)
        VirtFS.fs_lookup_call(f) { |p| file_readable?(p) }
      end

      def readable_real?(f)
        VirtFS.fs_lookup_call(f) { |p| file_readable_real?(p) }
      end

      def readlink(f)
        VirtFS.fs_lookup_call(f, false, false) { |p| file_readlink(p) }
      end

      def realdirpath(path, relative_to = nil) # ???
        VirtFS.expand_links(VirtFS.normalize_path(path, relative_to))
      end

      def realpath(path, relative_to = nil) # ???
        VirtFS.expand_links(VirtFS.normalize_path(path, relative_to))
      end

      def rename(oname, nname)
        fs1, p1 = VirtFS.path_lookup(oname)
        fs2, p2 = VirtFS.path_lookup(nname)
        raise SystemCallError, "Can't rename between filesystems" unless fs1 == fs2 # TODO: check exception
        VirtFS.fs_call(fs1) { file_rename(p1, p2) }
      end

      def setgid?(f)
        VirtFS.fs_lookup_call(f) { |p| file_setgid?(p) }
      end

      def setuid?(f)
        VirtFS.fs_lookup_call(f) { |p| file_setuid?(p) }
      end

      def size(f)
        VirtFS.fs_lookup_call(f) { |p| file_size(p) }
      end

      def size?(f)
        sz = size(f)
        return nil if sz == 0
        sz
      end

      def socket?(f)
        VirtFS.fs_lookup_call(f) { |p| file_socket?(p) }
      end

      def split(f)
        VfsRealFile.split(f)
      end

      def stat(f)
        VirtFS.fs_lookup_call(f) { |p| file_stat(p) }
      end

      def sticky?(f)
        VirtFS.fs_lookup_call(f) { |p| file_sticky?(p) }
      end

      def symlink(oname, nname)
        #
        # oname is the path to the original file in the global FS namespace.
        # It is not modified and used as the link target.
        #
        VirtFS.fs_lookup_call(nname) { |p| file_symlink(oname, p) }
      end

      def symlink?(f)
        VirtFS.fs_lookup_call(f, false, false) { |p| file_symlink?(p) }
      end

      def truncate(f, len)
        VirtFS.fs_lookup_call(f) { |p| file_truncate(p, len) }
      end

      def umask(*args)
        VfsRealFile.umask(*args)
      end

      def utime(atime, mtime, *files)
        nfp = 0
        files.each do |f|
          nfp += VirtFS.fs_lookup_call(f) { |p| file_utime(atime, mtime, p) }
        end
        nfp
      end

      def world_readable?(f)
        VirtFS.fs_lookup_call(f) { |p| file_world_readable?(p) }
      end

      def world_writable?(f)
        VirtFS.fs_lookup_call(f) { |p| file_world_writable?(p) }
      end

      def writable?(f)
        VirtFS.fs_lookup_call(f) { |p| file_writable?(p) }
      end

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

      #
      # Instantiate file instance.
      #

      def new(file_id, *args)
        if file_id.respond_to?(:to_int)
          fs_obj = VfsRealIO.new(file_id, *args)
        else
          parsed_args = FileModesAndOptions.new(*args)
          fs, p = VirtFS.path_lookup(file_id, false, false)
          fs_obj = VirtFS.fs_call(fs) { file_new(p, parsed_args, file_id, VDir.getwd) }
          fs_obj = ThinFileDelegator.new(fs_obj, file_id, p, parsed_args) if fs.thin_interface?
        end

        obj = allocate
        obj.send(:initialize, fs_obj, file_id)
        obj
      end
    end # class methods
  end
end
