require_relative 'thin/file'
require_relative 'thin/dir'
require_relative 'thin/file_class_methods'
require_relative 'thin/dir_class_methods'

module VirtFS::NativeFS # rubocop:disable Style/ClassAndModuleChildren
  class Thin
    attr_accessor :mount_point, :name

    include FileClassMethods
    include DirClassMethods

    def initialize
      @mount_point  = nil
      @name         = self.class.name
    end

    def thin_interface?
      true
    end

    def umount
      @mount_point = nil
    end
  end
end
