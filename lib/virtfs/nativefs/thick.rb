require_relative 'thick/file_class_methods'
require_relative 'thick/dir_class_methods'

module VirtFS::NativeFS # rubocop:disable Style/ClassAndModuleChildren
  class Thick
    attr_accessor :mount_point, :name

    include FileClassMethods
    include DirClassMethods

    def initialize(root = VfsRealFile::SEPARATOR)
      @mount_point  = nil
      @name         = self.class.name
      @root         = root
    end

    def thin_interface?
      false
    end

    def umount
      @mount_point = nil
    end

    def apply_root(path)
      VfsRealFile.join(@root, path)
    end
    private :apply_root
  end
end
