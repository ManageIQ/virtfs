#
# Dir class methods - are instance methods of filesystem instance.
#
module VirtFS::NativeFS # rubocop:disable Style/ClassAndModuleChildren
  class Thick
    module DirClassMethods
      def dir_delete(p)
        VfsRealDir.delete(apply_root(p))
      end

      def dir_entries(p)
        VfsRealDir.entries(apply_root(p))
      end

      def dir_exist?(p)
        VfsRealDir.exist?(apply_root(p))
      end

      def dir_foreach(p, &block)
        VfsRealDir.foreach(apply_root(p), &block)
      end

      def dir_mkdir(p, permissions)
        VfsRealDir.mkdir(apply_root(p), permissions)
      end

      def dir_new(fs_rel_path, hash_args, _open_path, cwd)
        owd = VfsRealDir.getwd
        begin
          VfsRealDir.chdir(cwd)
          return VfsRealDir.new(apply_root(fs_rel_path), hash_args)
        ensure
          VfsRealDir.chdir(owd)
        end
      end
    end
  end
end
