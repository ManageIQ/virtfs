require "pathname"

module VirtFS
  module Kernel # rubocop:disable ModuleLength
    @kernel_mutex = Mutex.new

    def self.inject # rubocop:disable AbcSize
      @kernel_mutex.synchronize do
        return false if @injected

        #
        # If the 'require' method is implemented in ruby (method(:require).source_location != nil)
        # and 'gem_original_require' is defined, then rubygems is active. Replace gem_original_require
        # with our VirtFS aware implementation of require - the rubygems require will call us.
        #
        # If the 'require' method is implemented in 'C' (method(:require).source_location == nil)
        # then rubygems is not active (even if 'gem_original_require' is defined). Replace 'require'
        # with our VirtFS aware implementation of require
        #
        @rubygems_active = method(:require).source_location && private_method_defined?(:gem_original_require)

        ::Kernel.module_exec(@rubygems_active) do |gems_active|
          if gems_active
            alias_method :virtfs_original_require, :gem_original_require
          else
            alias_method :virtfs_original_require, :require
          end
          private :virtfs_original_require

          alias_method :virtfs_original_load, :load
          private :virtfs_original_load

          define_method(:virtfs_require) do |file_name|
            VirtFS::Kernel.virtfs_require(file_name)
          end
          private :virtfs_require

          define_method(:virtfs_load) do |file_name, wrap = false|
            VirtFS::Kernel.virtfs_load(file_name, wrap)
          end
          private :virtfs_load
        end
        @injected = true
      end
    end

    def self.withdraw
      @kernel_mutex.synchronize do
        return false unless @injected
        raise "Cannot withdraw while VirtFS::Kernel is enabled" if @enabled

        ::Kernel.module_eval do
          remove_method :virtfs_original_require
          remove_method :virtfs_original_load
          remove_method :virtfs_require
          remove_method :virtfs_load
        end
        @injected = false
      end
      true
    end

    def self.enable
      @kernel_mutex.synchronize do
        return false if @enabled

        inject unless @injected

        ::Kernel.module_exec(@rubygems_active) do |gems_active|
          if gems_active
            alias_method :gem_original_require, :virtfs_require
          else
            alias_method :require, :virtfs_require
          end

          alias_method :load, :virtfs_load
        end
        @enabled = true
      end
      true
    end

    def self.disable
      @kernel_mutex.synchronize do
        return false unless @enabled

        ::Kernel.module_exec(@rubygems_active) do |gems_active|
          if gems_active
            alias_method :gem_original_require, :virtfs_original_require
          else
            alias_method :require, :virtfs_original_require
          end

          alias_method :load, :virtfs_original_load
        end
        @enabled = false
      end
      true
    end

    def self.virtfs_load(file_name, wrap)
      file_path = ::Pathname.new(file_name)
      return virtfs_original_load(file_name, wrap) unless file_path.extname == ".rb"
      file_path = canonical_path(file_path)
      raise LoadError, "cannot load such file -- #{file_name}" unless file_path
      eval_file(file_path, wrap)
      true
    end

    def self.virtfs_require(lib_name)
      lib_path = canonical_path(::Pathname.new(lib_name))
      raise LoadError, "cannot load such file -- #{lib_name}" unless lib_path
      return virtfs_original_require(lib_name) unless lib_path.extname == ".rb"
      return false if already_loaded(lib_path)
      eval_file(lib_path, false)
      $LOADED_FEATURES << lib_path.to_path
      true
    end

    def self.canonical_path(path)
      has_ext = path.extname != ""
      return path if path.absolute?
      $LOAD_PATH.each do |dir|
        full_path = path.expand_path(dir)
        if has_ext
          return full_path if full_path.file?
        else
          %w(.rb .so .o .dll).each do |ext|
            ext_path = full_path.sub_ext(ext)
            return ext_path if ext_path.file?
          end
        end
      end
      nil
    end

    def self.already_loaded(canonical_name)
      $LOADED_FEATURES.include?(canonical_name.to_path)
    end

    def self.eval_file(file_path, wrap)
      eval_binding = wrap ? Module.new.send(:binding) : TOPLEVEL_BINDING
      eval(file_path.read, eval_binding, file_path.to_path) # rubocop:disable Lint/Eval
    end
  end
end
