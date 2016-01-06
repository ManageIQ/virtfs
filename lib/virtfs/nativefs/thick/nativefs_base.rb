module VirtFS::NativeFS # rubocop:disable Style/ClassAndModuleChildren
  class Thick
    attr_accessor :mount_point, :name

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
