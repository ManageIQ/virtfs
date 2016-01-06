#
# Dir class methods - are instance methods of filesystem instance.
#
module VirtFS::NativeFS # rubocop:disable Style/ClassAndModuleChildren
  class Thick
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

    def dir_new(_fs_rel_path, hash_args, open_path, cwd)
      owd = VfsRealDir.getwd
      begin
        VfsRealDir.chdir(cwd)
        return VfsRealDir.new(open_path, hash_args)
      ensure
        VfsRealDir.chdir(owd)
      end
    end
  end
end
