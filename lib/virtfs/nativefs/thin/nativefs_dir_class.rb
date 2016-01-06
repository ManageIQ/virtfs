#
# Dir class methods - are instance methods of filesystem instance.
#
module VirtFS::NativeFS # rubocop:disable Style/ClassAndModuleChildren
  class Thin
    def dir_delete(p)
      VfsRealDir.delete(p)
    end

    def dir_entries(p)
      VfsRealDir.entries(p)
    end

    def dir_exist?(p)
      VfsRealDir.exist?(p)
    end

    def dir_foreach(p, &block)
      VfsRealDir.foreach(p, &block)
    end

    def dir_mkdir(p, permissions)
      VfsRealDir.mkdir(p, permissions)
    end

    def dir_new(fs_rel_path, hash_args, _open_path, _cwd)
      Dir.new(self, lookup_dir(fs_rel_path, hash_args), hash_args)
    end

    private

    def lookup_dir(fs_rel_path, hash_args)
      #
      # Get filesystem-specific handel for directory instance.
      #
      VfsRealDir.new(fs_rel_path, hash_args)
    end
  end
end
