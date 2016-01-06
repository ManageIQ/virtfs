module VirtFS
  class NotImplementedError < StandardError
    def initialize(fs, method)
      super "Feature: #{method} - not implemented in #{fs.name} filesystem"
    end
  end

  class NoContextError < StandardError
    def initialize
      super "No filesystem context defined for thread group: #{Thread.current.group.inspect}"
    end
  end
end
