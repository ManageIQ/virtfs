require "log_decorator"

module VirtFS
  # FS-specific state under which FS calls occur.
  #
  # VirtFS maps an independent context instance to each
  # Ruby thread group, and internally switches to it before
  # dispatching target FS calls from that thread.
  # This class implements the core functionality behind the FS context
  class Context
    include LogDecorator::Logging

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

    # Set key used to uniquely identify the context
    #
    # @param val [String] context identifier
    # @raise [RuntimeError] if key already assigned
    def key=(val)
      @dir_mutex.synchronize do
        raise "Context already assigned to key: #{@key}" if !@key.nil? && !val.nil?
        @key = val
      end
    end

    # Mount the specified FS instance at the specified mount point.
    # This registers specified fs to be accessed through the specified mount
    # point via internal mechanisms. After this point any calls to this mount
    # point through VirtFS under this context will be mapped through the specified
    # fs instance
    #
    # @param fs_instance [VirtFS::FS] instance of VirtFS implementation corresponding
    #   to filesystem to mount
    # @param mount_point [String] path which to mount filesystem under
    #
    # @raise [SystemCallError] if mount point cannot be resolved
    # @raise [RuntimeError] if mount point is being used
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

    # Unmount the FS mounted at the specified mount point
    #
    # @param mount_point [String] mount point to unmount
    # @raise [RuntimeError] if mount point is not mounted
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

    # @return [Array<String>] array of mount points
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
      mp = full_path(mount_point, true, *cwd_root)
      mp += VfsRealFile::SEPARATOR unless mp.end_with?(VfsRealFile::SEPARATOR)
      @mount_mutex.synchronize do
        @fs_lookup[mp]
      end
    end

    # @return [Boolean] indicating if mount point is mounted
    def mounted?(mount_point)
      !fs_on(mount_point).nil?
    end

    # Change virtual file system root, after which all root calls to mount point will
    # be mapped to specified dir
    #
    # @param dir [String] new dir to assign as virtfs context root
    # @raise [SystemCallError] if specified dir does not exist
    def chroot(dir)
      raise SystemCallError.new(dir, Errno::ENOENT::Errno) unless dir_exist?(dir)
      @dir_mutex.synchronize do
        @root = full_path(dir, true, @cwd, @root)
        @cwd  = VfsRealFile::SEPARATOR
      end
      0
    end

    # Invoke block with the specified root, restoring before returning
    #
    # @see chroot
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

    # @return [Boolean] indicating if specified dir exists
    def dir_exist?(dir)
      begin
        fs, p = path_lookup(dir)
      rescue Errno::ENOENT
        return false
      end
      VirtFS.fs_call(fs) { dir_exist?(p) }
    end

    # Change virtual filesystem working directory
    #
    # @param dir [String] new dir to assign to virtfs cwd
    def chdir(dir)
      fs = path = nil
      @dir_mutex.synchronize do
        nwd = remove_root(local_path(dir, @cwd, @root), @root)
        fs, path = mount_lookup(nwd)
        @cwd = nwd
      end
      fs.dir_chdir(path) if fs.respond_to?(:dir_chdir)
    end

    # @return [String] current filesystem working directory
    def getwd
      @cwd
    end

    # Expand symbolic links and perform mount indirection look up.
    #
    # @param path [String] path to lookup
    # @param raise_full_path [Boolean] indicates if error should be raised if lookup fails
    # @param include_last [Boolean] indicates if last path component should be returned
    #
    # @raise [RunTimeError] if path could not be looked up and raise_full_path is true
    # @raise [SystemCallError] if path could not be looked up
    #
    # @api private
    # @see #mount_lookup
    # @see #expand_links
    #
    def path_lookup(path, raise_full_path = false, include_last = true)
      mount_lookup(full_path(path, include_last, *cwd_root))
    rescue Errno::ENOENT
      raise if raise_full_path
      # so we report the original path.
      raise SystemCallError.new(path, Errno::ENOENT::Errno)
    end

    # Expand symbolic links in the path.
    # This must be done here, because a symlink in one file system
    # can point to a file in another filesystem.
    #
    # @api private
    # @param p [String] path to lookup
    # @param include_last [Boolean] indicates if last path component should be returned
    def expand_links(p, include_last = true)
      _log.debug "path = #{p}"
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
      VfsRealFile.join(cp, last_component.to_s)
    end

    # Helper to change virtual filesystem working directory to filesystem root
    # @api private
    #
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

    def local_path(path, cwd, root)
      lpath = path || cwd
      lpath = VfsRealFile.join(cwd, path) if Pathname(path).relative?
      lpath = VirtFS.normalize_path(lpath)
      apply_root(lpath, root)
    end

    def full_path(path, include_last, cwd, root)
      expand_links(local_path(path, cwd, root), include_last)
    end

    #
    # Mount indirection look up.
    # Given a path, return its corresponding file system
    # and the part of the path relative to that file system.
    # It assumes symbolic links have already been expanded.
    # @api private
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
