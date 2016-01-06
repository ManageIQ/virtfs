VfsRealDir       = ::Dir
VfsRealFile      = ::File
VfsRealIO        = ::IO

module VirtFS
  @activated = false

  def self.activated?
    @activated
  end

  def self.activate!
    raise "VirtFS.activate! already activated" if @activated
    @activated = true

    Object.class_eval do
      remove_const(:Dir)
      remove_const(:File)
      remove_const(:IO)

      const_set(:Dir,  VirtFS::VDir)
      const_set(:File, VirtFS::VFile)
      const_set(:IO,   VirtFS::VIO)
    end
    true
  end

  def self.deactivate!
    raise "VirtFS.deactivate! not activated" unless @activated
    @activated = false

    Object.class_eval do
      remove_const(:Dir)
      remove_const(:File)
      remove_const(:IO)

      const_set(:Dir,  VfsRealDir)
      const_set(:File, VfsRealFile)
      const_set(:IO,   VfsRealIO)
    end
    true
  end

  def self.with
    if activated?
      yield
    else
      begin
        activate!
        yield
      ensure
        deactivate!
      end
    end
  end

  def self.without
    if !activated?
      yield
    else
      begin
        deactivate!
        yield
      ensure
        activate!
      end
    end
  end
end
