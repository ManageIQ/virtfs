require_relative 'thick/file_class_methods'
require_relative 'thick/dir_class_methods'

module VirtFS::NativeFS # rubocop:disable Style/ClassAndModuleChildren
  class Thick
    attr_accessor :mount_point, :name

    include FileClassMethods
    include DirClassMethods

    def initialize
      @mount_point  = nil
      @name         = self.class.name
    end

    def thin_interface?
      false
    end

    def umount
      @mount_point = nil
    end
  end
end
