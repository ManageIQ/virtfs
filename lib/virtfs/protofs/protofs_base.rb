class ProtoFS
	attr_accessor :mount_point, :name

  def initialize
    @mount_point  = nil
    @name         = self.class.name
  end

  def umount
    @mount_point = nil
  end
end
