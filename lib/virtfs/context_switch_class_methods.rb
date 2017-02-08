module VirtFS
  module ContextSwitchClassMethods
    def context_manager
      ContextManager
    end

    def context
      context_manager.current.current_context
    end

    def context!
      context_manager.current!.current_context
    end

    def mount(fs_instance, mount_point)
      context.mount(fs_instance, mount_point)
    end

    def umount(mount_point)
      context.umount(mount_point)
    end

    def mounted?(mount_point)
      context.mounted?(mount_point)
    end

    def cwd=(dir)
      context.restore_cwd_root(dir, nil)
    end

    def root
      _cwd, root = context.cwd_root
      root
    end

    def dir_chroot(dir)
      context.chroot(dir)
    end

    def dir_chdir(dir)
      context.chdir(dir)
    end

    def dir_getwd
      context.getwd
    end

    #
    # Expand symbolic links and perform mount indirection look up.
    #
    def path_lookup(path, raise_full_path = false, include_last = true)
      context.path_lookup(path, raise_full_path, include_last)
    end

    #
    # Expand symbolic links in the path.
    # This must be done here, because a symlink in one file system
    # can point to a file in another filesystem.
    #
    def expand_links(p, include_last = true)
      context.expand_links(p, include_last)
    end

    def normalize_path(p, relative_to = nil)
      # When running on windows, File.expand_path will add a drive letter.
      # Remove it if it's there.
      VfsRealFile.expand_path(p, relative_to || context.getwd).sub(/^[a-zA-Z]:/, "") # XXX
    end

    # Invoke block withing the given filesystem context
    #
    # @api private
    # @param fs [VirtFS::FS] filesystem intstance through which to invoke block
    # @param path [String] path to specify to block
    #
    # @raise [VirtFS::NotImplementedError] if filesystem method does not exist
    #
    def fs_call(fs, path = nil, &block)
      block.arity < 1 ? fs.instance_eval(&block) : fs.instance_exec(path, &block)
    rescue NoMethodError => err
      STDOUT.puts err.to_s
      STDOUT.puts err.backtrace.join("\n")
      raise VirtFS::NotImplementedError.new(fs, err.name)
    end

  # Invoke block using fully resolved filesystem path
  #
  # @api private
  # @see .fs_call
  # @see Context#path_lookup
    def fs_lookup_call(path, raise_full_path = false, include_last = true, &block)
      fs, p = path_lookup(path, raise_full_path, include_last)
      fs_call(fs, p, &block)
    end
  end
end
