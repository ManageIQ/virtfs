module VirtFS
  class Context
    attr_reader :key

    def initialize
      @mount_points = []
      @fs_lookup    = {}
      @mount_mutex  = Mutex.new
      @dir_mutex    = Mutex.new
      @saved_root   = nil
      @saved_cwd    = nil
      @root         = VfsRealFile::SEPARATOR
      @cwd          = @root
      @key          = nil
    end

    def key=(val)
      @dir_mutex.synchronize do
        raise "Context already assigned to key: #{@key}" if !@key.nil? && !val.nil?
        @key = val
      end
    end

    def mount(fs_instance, mount_point)
      mp_display  = mount_point

      raise "mount: invalid filesystem object #{fs_instance.class.name}" unless fs_instance.respond_to?(:mount_point)
      raise "mount: filesystem is busy" if fs_instance.mount_point

      begin
        mount_point = full_path(mount_point, true, *cwd_root)
      rescue Errno::ENOENT
        raise SystemCallError.new(mp_display, Errno::ENOENT::Errno)
      end
      mount_point += VfsRealFile::SEPARATOR unless mount_point.end_with?(VfsRealFile::SEPARATOR)

      @mount_mutex.synchronize do
        raise "mount: mount point #{mp_display} is busy" if @fs_lookup[mount_point]
        fs_instance.mount_point = mount_point
        @fs_lookup[mount_point] = fs_instance
        @mount_points.push(mount_point).sort_by!(&:length).reverse!
      end
      nil
    end

    def umount(mount_point)
      mount_point = full_path(mount_point, true, *cwd_root)
      @mount_mutex.synchronize do
        mp_display = mount_point
        mount_point += VfsRealFile::SEPARATOR unless mount_point.end_with?(VfsRealFile::SEPARATOR)
        raise "umount: nothing mounted on #{mp_display}" unless @fs_lookup[mount_point]
        @fs_lookup.delete(mount_point).umount
        @mount_points.delete(mount_point)
      end
      nil
    end

    def mount_points
      @mount_mutex.synchronize do
        @mount_points.collect do |p|
          if p == VfsRealFile::SEPARATOR
            VfsRealFile::SEPARATOR
          else
            p.chomp(VfsRealFile::SEPARATOR)
          end
        end
      end
    end

    def fs_on(mount_point)
      mount_point += VfsRealFile::SEPARATOR unless mount_point.end_with?(VfsRealFile::SEPARATOR)
      @mount_mutex.synchronize do
        @fs_lookup[mount_point]
      end
    end

    def mounted?(mount_point)
      !fs_on(mount_point).nil?
    end

    def chroot(dir)
      raise SystemCallError.new(dir, Errno::ENOENT::Errno) unless dir_exist?(dir)
      @dir_mutex.synchronize do
        @root = full_path(dir, true, @cwd, @root)
        @cwd  = VfsRealFile::SEPARATOR
      end
      0
    end

    def with_root(dir)
      raise SystemCallError.new(dir, Errno::ENOENT::Errno) unless dir_exist?(dir)
      @dir_mutex.synchronize do
        raise "Cannot nest with_root blocks" unless @saved_root.nil?
        @saved_root = @root
        @saved_cwd  = @cwd
        @root = full_path(dir, true, @cwd, @root)
        @cwd  = VfsRealFile::SEPARATOR
      end
      begin
        yield
      ensure
        @dir_mutex.synchronize do
          @root       = @saved_root
          @cwd        = @saved_cwd
          @saved_root = nil
          @saved_cwd  = nil
        end
      end
    end

    def dir_exist?(dir)
      begin
        fs, p = path_lookup(dir)
      rescue Errno::ENOENT
        return false
      end
      VirtFS.fs_call(fs) { dir_exist?(p) }
    end

    def chdir(dir)
      fs = path = nil
      @dir_mutex.synchronize do
        nwd = remove_root(full_path(dir, true, @cwd, @root), @root)
        fs, path = mount_lookup(nwd)
        @cwd = nwd
      end
      fs.dir_chdir(path) if fs.respond_to?(:dir_chdir)
    end

    def getwd
      @cwd
    end

    #
    # Expand symbolic links and perform mount indirection look up.
    #
    def path_lookup(path, raise_full_path = false, include_last = true)
      mount_lookup(full_path(path, include_last, *cwd_root))
    rescue Errno::ENOENT
      raise if raise_full_path
      # so we report the original path.
      raise SystemCallError.new(path, Errno::ENOENT::Errno)
    end

    #
    # Expand symbolic links in the path.
    # This must be done here, because a symlink in one file system
    # can point to a file in another filesystem.
    #
    def expand_links(p, include_last = true)
      cp = VfsRealFile::SEPARATOR
      components = p.split(VfsRealFile::SEPARATOR)
      components.shift if components[0] == "" # root
      last_component = components.pop unless include_last

      #
      # For each component of the path, check to see
      # if it's a symbolic link. If so, expand it
      # relative to its base directory.
      #
      components.each do |c|
        ncp = VfsRealFile.join(cp, c)
        #
        # Each file system knows how to check for,
        # and read, its own links.
        #
        fs, lp = mount_lookup(ncp)
        if fs.file_symlink?(lp)
          sl = fs.file_readlink(lp)
          cp = sl[0, 1] == VfsRealFile::SEPARATOR ? sl : VfsRealFile.join(cp, sl)
        else
          cp = ncp
        end
      end
      return cp if include_last
      VfsRealFile.join(cp, last_component)
    end

    def cwd_root
      @dir_mutex.synchronize do
        return @cwd, @root
      end
    end

    def restore_cwd_root(cwd, root)
      @dir_mutex.synchronize do
        @cwd  = cwd  if cwd
        @root = root if root
      end
    end

    private

    def full_path(path, include_last, cwd, root)
      local_path = path || cwd
      local_path = VfsRealFile.join(cwd, path) if Pathname(path).relative?
      local_path = VirtFS.normalize_path(local_path)
      local_path = apply_root(local_path, root)
      expand_links(local_path, include_last)
    end

    #
    # Mount indirection look up.
    # Given a path, return its corresponding file system
    # and the part of the path relative to that file system.
    # It assumes symbolic links have already been expanded.
    #
    def mount_lookup(path) # private
      spath = "#{path}#{VfsRealFile::SEPARATOR}"
      @mount_mutex.synchronize do
        @mount_points.each do |mp|
          next if mp.length > spath.length
          next unless spath.start_with?(mp)
          return @fs_lookup[mp], path if mp == VfsRealFile::SEPARATOR  # root
          return @fs_lookup[mp], VfsRealFile::SEPARATOR if mp == spath # path is the mount point
          return @fs_lookup[mp], path.sub(mp, VfsRealFile::SEPARATOR)
        end
      end
      raise SystemCallError.new(path, Errno::ENOENT::Errno)
    end

    def under_root?(path, root)
      return true if path == root
      path.start_with?(root + VfsRealFile::SEPARATOR)
    end

    def apply_root(path, root)
      return path if root == VfsRealFile::SEPARATOR
      VfsRealFile.join(root, path)
    end

    def remove_root(path, root)
      return path if root == VfsRealFile::SEPARATOR
      return VfsRealFile::SEPARATOR if path == root
      return path unless under_root?(path, root)
      path.sub(root, "")
    end
  end
end
