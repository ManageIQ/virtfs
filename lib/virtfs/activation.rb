module VirtFS
  module Activation
    def activated?
      @activated
    end

    def activate!
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

    def deactivate!
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

    def with
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

    def without
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
end
