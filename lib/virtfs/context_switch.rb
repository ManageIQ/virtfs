module VirtFS
  def self.context_manager
    ContextManager
  end

  def self.context
    context_manager.current.current_context
  end

  def self.context!
    context_manager.current!.current_context
  end

  def self.mount(fs_instance, mount_point)
    context.mount(fs_instance, mount_point)
  end

  def self.umount(mount_point)
    context.umount(mount_point)
  end

  def self.mounted?(mount_point)
    context.mounted?(mount_point)
  end

  def self.cwd=(dir)
    context.restore_cwd_root(dir, nil)
  end

  def self.root
    _cwd, root = context.cwd_root
    root
  end

  def self.dir_chroot(dir)
    context.chroot(dir)
  end

  def self.dir_chdir(dir)
    context.chdir(dir)
  end

  def self.dir_getwd
    context.getwd
  end

  #
  # Expand symbolic links and perform mount indirection look up.
  #
  def self.path_lookup(path, raise_full_path = false, include_last = true)
    context.path_lookup(path, raise_full_path, include_last)
  end

  #
  # Expand symbolic links in the path.
  # This must be done here, because a symlink in one file system
  # can point to a file in another filesystem.
  #
  def self.expand_links(p, include_last = true)
    context.expand_links(p, include_last)
  end

  def self.normalize_path(p, relative_to = nil)
    # When running on windows, File.expand_path will add a drive letter.
    # Remove it if it's there.
    VfsRealFile.expand_path(p, relative_to || context.getwd).sub(/^[a-zA-Z]:/, "") # XXX
  end

  def self.fs_call(fs, path = nil, &block)
    block.arity < 1 ? fs.instance_eval(&block) : fs.instance_exec(path, &block)
  rescue NoMethodError => err
    STDOUT.puts err.to_s
    STDOUT.puts err.backtrace.join("\n")
    raise VirtFS::NotImplementedError.new(fs, err.name)
  end

  def self.fs_lookup_call(path, raise_full_path = false, include_last = true, &block)
    fs, p = path_lookup(path, raise_full_path, include_last)
    fs_call(fs, p, &block)
  end
end
