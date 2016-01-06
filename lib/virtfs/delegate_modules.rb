require "delegate"

module VirtFS
  def self.delegate_module(superclass)
    mod = Module.new
    methods = superclass.instance_methods
    methods -= ::Delegator.public_api
    methods -= [:to_s, :inspect, :=~, :!~, :===]

    mod.module_eval do
      def __getobj__  # :nodoc:
        unless defined?(@delegate_dc_obj)
          return yield if block_given?
          __raise__ ::ArgumentError, "not delegated"
        end
        @delegate_dc_obj
      end

      def __setobj__(obj)  # :nodoc:
        __raise__ ::ArgumentError, "cannot delegate to self" if self.equal?(obj)
        @delegate_dc_obj = obj
      end

      methods.each do |method|
        define_method(method, Delegator.delegating_block(method))
      end
    end

    mod.define_singleton_method :public_instance_methods do |all=true|
      super(all) - superclass.protected_instance_methods
    end

    mod.define_singleton_method :protected_instance_methods do |all=true|
      super(all) | superclass.protected_instance_methods
    end
    mod
  end

  FileInstanceDelegate = delegate_module(VfsRealFile)
  IOInstanceDelegate   = delegate_module(VfsRealIO)
  DirInstanceDelegate  = delegate_module(VfsRealDir)
end
