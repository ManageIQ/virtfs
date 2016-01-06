module VirtFS
  class ContextManager
    attr_reader :thread_group

    @context_managers = {}
    @context_manager_mutex = Mutex.new

    def self.my_thread_group
      Thread.current.group || ThreadGroup::Default
    end

    def self.current
      @context_manager_mutex.synchronize do
        @context_managers[my_thread_group] ||= ContextManager.new(my_thread_group)
      end
    end

    def self.current!
      @context_manager_mutex.synchronize do
        @context_managers[my_thread_group] || raise(VirtFS::NoContextError.new)
      end
    end

    def self.context
      current.current_context
    end

    def self.context!
      current!.current_context
    end

    def self.managers
      @context_manager_mutex.synchronize do
        @context_managers.dup
      end
    end

    def self.manager_for(tgroup)
      raise ArgumentError, "value must be a ThreadGroup object" unless tgroup.is_a?(ThreadGroup)
      @context_manager_mutex.synchronize do
        @context_managers[tgroup]
      end
    end

    def self.new_manager_for(tgroup)
      raise ArgumentError, "value must be a ThreadGroup object" unless tgroup.is_a?(ThreadGroup)
      @context_manager_mutex.synchronize do
        @context_managers[tgroup] = ContextManager.new(tgroup)
      end
    end

    def self.remove_manager_for(tgroup)
      raise ArgumentError, "value must be a ThreadGroup object" unless tgroup.is_a?(ThreadGroup)
      @context_manager_mutex.synchronize do
        @context_managers.delete(tgroup)
      end
    end

    def self.reset_all
      @context_manager_mutex.synchronize do
        @context_managers = {}
      end
    end

    def initialize(thread_group)
      @thread_group  = thread_group
      @context_mutex = Mutex.new
      reset
    end

    def [](key)
      @context_mutex.synchronize do
        @contexts[key]
      end
    end

    #
    # Change context without saving current context state.
    #
    def []=(key, context)
      raise ArgumentError, "Context must be a VirtFS::Context object" if context && !context.is_a?(Context)
      raise ArgumentError, "Cannot change the default context" if key == :default
      @context_mutex.synchronize do
        if context.nil?
          ctx = @contexts.delete(key)
          ctx.key = nil
          return ctx
        end
        raise "Context for given key already exists" if @contexts[key]
        context.key = key
        @contexts[key] = context
      end
    end

    def activated?
      @context_mutex.synchronize do
        !@saved_context.nil?
      end
    end

    #
    # Save the current context state and change context.
    #
    def activate!(key)
      @context_mutex.synchronize do
        raise "Context already activated" if @saved_context
        raise "Context for given key doesn't exist" unless (ctx = @contexts[key])
        @saved_context = @current_context
        @current_context = ctx
        @saved_context # returns the pre-activation context.
      end
    end

    #
    # Restore the context state saved by activate!
    #
    def deactivate!
      @context_mutex.synchronize do
        raise "Context not activated" unless @saved_context
        ret = @current_context
        @current_context = @saved_context
        @saved_context = nil
        ret # returns the pre-deactivated context.
      end
    end

    def current_context
      @context_mutex.synchronize do
        @current_context
      end
    end

    def current_context=(key)
      @context_mutex.synchronize do
        raise "Context for given key doesn't exist" unless (ctx = @contexts[key])
        @current_context = ctx
      end
    end

    def reset
      @context_mutex.synchronize do
        @contexts           = {}
        @saved_context      = nil
        @contexts[:default] = Context.new
        @current_context    = @contexts[:default]
      end
    end

    def with(key)
      activate!(key)
      begin
        yield
      ensure
        deactivate!
      end
    end

    def without
      if !activated?
        yield
      else
        begin
          saved_context = deactivate!
          yield
        ensure
          activate!(saved_context.key)
        end
      end
    end
  end
end
