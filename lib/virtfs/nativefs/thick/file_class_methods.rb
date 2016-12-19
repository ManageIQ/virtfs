#
# File class methods - are instance methods of filesystem instance.
#
module VirtFS::NativeFS # rubocop:disable Style/ClassAndModuleChildren
  class Thick
    module FileClassMethods
      def file_atime(p)
        VfsRealFile.atime(p)
      end

      def file_blockdev?(p)
        VfsRealFile.blockdev?(p)
      end

      def file_chardev?(p)
        VfsRealFile.chardev?(p)
      end

      def file_chmod(permission, p)
        VfsRealFile.chmod(permission, p)
      end

      def file_chown(owner, group, p)
        VfsRealFile.chown(owner, group, p)
      end

      def file_ctime(p)
        VfsRealFile.ctime(p)
      end

      def file_delete(p)
        VfsRealFile.delete(p)
      end

      def file_directory?(p)
        VfsRealFile.directory?(p)
      end

      def file_executable?(p)
        VfsRealFile.executable?(p)
      end

      def file_executable_real?(p)
        VfsRealFile.executable_real?(p)
      end

      def file_exist?(p)
        VfsRealFile.exist?(p)
      end

      def file_file?(p)
        VfsRealFile.file?(p)
      end

      def file_ftype(p)
        VfsRealFile.ftype(p)
      end

      def file_grpowned?(p)
        VfsRealFile.grpowned?(p)
      end

      def file_identical?(p1, p2)
        VfsRealFile.identical?(p1, p2)
      end

      def file_lchmod(permission, p)
        VfsRealFile.lchmod(permission, p)
      end

      def file_lchown(owner, group, p)
        VfsRealFile.lchown(owner, group, p)
      end

      def file_link(p1, p2)
        VfsRealFile.link(p1, p2)
      end

      def file_lstat(p)
        VfsRealFile.lstat(p)
      end

      def file_mtime(p)
        VfsRealFile.mtime(p)
      end

      def file_owned?(p)
        VfsRealFile.owned?(p)
      end

      def file_pipe?(p)
        VfsRealFile.pipe?(p)
      end

      def file_readable?(p)
        VfsRealFile.readable?(p)
      end

      def file_readable_real?(p)
        VfsRealFile.readable_real?(p)
      end

      def file_readlink(p)
        VfsRealFile.readlink(p)
      end

      def file_rename(p1, p2)
        VfsRealFile.rename(p1, p2)
      end

      def file_setgid?(p)
        VfsRealFile.setgid?(p)
      end

      def file_setuid?(p)
        VfsRealFile.setuid?(p)
      end

      def file_size(p)
        VfsRealFile.size(p)
      end

      def file_socket?(p)
        VfsRealFile.socket?(p)
      end

      def file_stat(p)
        VfsRealFile.stat(p)
      end

      def file_sticky?(p)
        VfsRealFile.sticky?(p)
      end

      def file_symlink(oname, p)
        VfsRealFile.symlink(oname, p)
      end

      def file_symlink?(p)
        VfsRealFile.symlink?(p)
      end

      def file_truncate(p, len)
        VfsRealFile.truncate(p, len)
      end

      def file_utime(atime, mtime, p)
        VfsRealFile.utime(atime, mtime, p)
      end

      def file_world_readable?(p)
        VfsRealFile.world_readable?(p)
      end

      def file_world_writable?(p)
        VfsRealFile.world_writable?(p)
      end

      def file_writable?(p)
        VfsRealFile.writable?(p)
      end

      def file_writable_real?(p)
        VfsRealFile.writable_real?(p)
      end

      def file_new(_f, parsed_args, open_path, cwd)
        owd = VfsRealDir.getwd
        begin
          VfsRealDir.chdir(cwd)
          return VfsRealFile.new(open_path, *parsed_args.args)
        ensure
          VfsRealDir.chdir(owd)
        end
      end
    end
  end
end
