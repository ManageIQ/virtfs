module VirtFS
  # Dispatches Dir calls to/from VirtFS and the 'Thin' subsystem
  #
  class ThinDirDelegator
    # Instance methods
    def initialize(fs_dir_obj, creation_path, fs_path, _hash_args)
      @fs_dir_obj        = fs_dir_obj
      @creation_path     = creation_path
      @full_path         = VfsRealFile.join(fs_dir_obj.fs.mount_point, fs_path)
      @fs_path           = fs_path
      @dir_closed        = false
      @raw_pos           = 0 # FS-specific position
      @cur_tell          = -1
      @next_tell         = 0
      @tells             = []
      @raw_pos_to_tell   = {}
    end

    def close
      raise IOError, "closed directory" if @dir_closed
      @fs_dir_obj.close
      @dir_closed = true
      nil
    end

    def each
      return to_enum(__method__) unless block_given?
      raise IOError, "closed directory" if @dir_closed
      while (file_name = read)
        yield(file_name)
      end
      self
    end

    def path
      @creation_path
    end
    alias_method :to_path, :path

    def pos=(tell_val)
      raise IOError, "closed directory" if @dir_closed
      seek(tell_val)
      tell_val
    end

    def read
      raise IOError, "closed directory" if @dir_closed
      file_name, @raw_pos = @fs_dir_obj.read(@raw_pos)
      file_name
    end

    def rewind
      raise IOError, "closed directory" if @dir_closed
      @raw_pos = 0
      self
    end

    def seek(tell_val)
      raise IOError, "closed directory" if @dir_closed
      return self unless (new_pos = @tells[tell_val])
      @cur_tell = tell_val
      @raw_pos = new_pos
      self
    end

    def tell
      raise IOError, "closed directory" if @dir_closed
      if (tell_val = @raw_pos_to_tell[@raw_pos])
        return @cur_tell = tell_val
      end
      @cur_tell = @next_tell
      @tells[@cur_tell] = @raw_pos
      @raw_pos_to_tell[@raw_pos] = @cur_tell
      @next_tell += 1
      @cur_tell
    end
    alias_method :pos, :tell
  end
end
