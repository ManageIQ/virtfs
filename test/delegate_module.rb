require "delegate"

begin

  def DelegateModule(superclass)
    klass = Module.new
    methods = superclass.instance_methods
    methods -= ::Delegator.public_api
    methods -= [:to_s,:inspect,:=~,:!~,:===]
    klass.module_eval do
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
    klass.define_singleton_method :public_instance_methods do |all=true|
      super(all) - superclass.protected_instance_methods
    end
    klass.define_singleton_method :protected_instance_methods do |all=true|
      super(all) | superclass.protected_instance_methods
    end
    return klass
  end

  FileDelegate = DelegateModule(File)

  class MyIO
  end

  class MyFile < MyIO
    include FileDelegate

    def initialize(dobj)
      __setobj__(dobj)
    end
  end

  fobj = File.new(__FILE__, "r")

  mf = MyFile.new(fobj)

  puts "mf.is_a?(MyFile) = #{mf.is_a?(MyFile)}"
  puts "mf.is_a?(MyIO)   = #{mf.is_a?(MyIO)}"

  puts
  mf.each { |l| puts l }
  mf.close

rescue => err
  puts err.to_s
  puts err.backtrace.join("\n")
end
