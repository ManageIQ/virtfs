#
# File class methods - are instance methods of filesystem instance.
#
module VirtFS::NativeFS # rubocop:disable Style/ClassAndModuleChildren
  class Thin
    module FileClassMethods # rubocop:disable ModuleLength
      def file_atime(p)
        VfsRealFile.atime(p)
      end

      def file_blockdev?(p)
        VfsRealFile.blockdev?(apply_root(p))
      end

      def file_chardev?(p)
        VfsRealFile.chardev?(apply_root(p))
      end

      def file_chmod(permission, p)
        VfsRealFile.chmod(permission, apply_root(p))
      end

      def file_chown(owner, group, p)
        VfsRealFile.chown(owner, group, apply_root(p))
      end

      def file_ctime(p)
        VfsRealFile.ctime(apply_root(p))
      end

      def file_delete(p)
        VfsRealFile.delete(apply_root(p))
      end

      def file_directory?(p)
        VfsRealFile.directory?(apply_root(p))
      end

      def file_executable?(p)
        VfsRealFile.executable?(apply_root(p))
      end

      def file_executable_real?(p)
        VfsRealFile.executable_real?(apply_root(p))
      end

      def file_exist?(p)
        VfsRealFile.exist?(apply_root(p))
      end

      def file_file?(p)
        VfsRealFile.file?(apply_root(p))
      end

      def file_ftype(p)
        VfsRealFile.ftype(apply_root(p))
      end

      def file_grpowned?(p)
        VfsRealFile.grpowned?(apply_root(p))
      end

      def file_identical?(p1, p2)
        VfsRealFile.identical?(apply_root(p1), apply_root(p2))
      end

      def file_lchmod(permission, p)
        VfsRealFile.lchmod(permission, apply_root(p))
      end

      def file_lchown(owner, group, p)
        VfsRealFile.lchown(owner, group, apply_root(p))
      end

      def file_link(p1, p2)
        VfsRealFile.link(apply_root(p1), apply_root(p2))
      end

      def file_lstat(p)
        VfsRealFile.lstat(apply_root(p))
      end

      def file_mtime(p)
        VfsRealFile.mtime(apply_root(p))
      end

      def file_owned?(p)
        VfsRealFile.owned?(apply_root(p))
      end

      def file_pipe?(p)
        VfsRealFile.pipe?(apply_root(p))
      end

      def file_readable?(p)
        VfsRealFile.readable?(apply_root(p))
      end

      def file_readable_real?(p)
        VfsRealFile.readable_real?(apply_root(p))
      end

      def file_readlink(p)
        VfsRealFile.readlink(apply_root(p))
      end

      def file_rename(p1, p2)
        VfsRealFile.rename(apply_root(p1), apply_root(p2))
      end

      def file_setgid?(p)
        VfsRealFile.setgid?(apply_root(p))
      end

      def file_setuid?(p)
        VfsRealFile.setuid?(apply_root(p))
      end

      def file_size(p)
        VfsRealFile.size(apply_root(p))
      end

      def file_socket?(p)
        VfsRealFile.socket?(apply_root(p))
      end

      def file_stat(p)
        VfsRealFile.stat(apply_root(p))
      end

      def file_sticky?(p)
        VfsRealFile.sticky?(apply_root(p))
      end

      def file_symlink(oname, p)
        VfsRealFile.symlink(oname, apply_root(p))
      end

      def file_symlink?(p)
        VfsRealFile.symlink?(apply_root(p))
      end

      def file_truncate(p, len)
        VfsRealFile.truncate(apply_root(p), len)
      end

      def file_utime(atime, mtime, p)
        VfsRealFile.utime(atime, mtime, apply_root(p))
      end

      def file_world_readable?(p)
        VfsRealFile.world_readable?(apply_root(p))
      end

      def file_world_writable?(p)
        VfsRealFile.world_writable?(apply_root(p))
      end

      def file_writable?(p)
        VfsRealFile.writable?(apply_root(p))
      end

      def file_writable_real?(p)
        VfsRealFile.writable_real?(apply_root(p))
      end

      def file_new(f, parsed_args, _open_path, _cwd)
        File.new(self, lookup_file(apply_root(f), parsed_args), parsed_args)
      end

      private

      def lookup_file(f, parsed_args)
        #
        # Get filesystem-specific handle for file instance.
        #
        VfsRealFile.new(f, parsed_args.mode_bits & ~VfsRealFile::APPEND, :binmode => true)
      end
    end
  end
end
