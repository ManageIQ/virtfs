module VirtFS
  #
  # IO objects are not instantiated directly, because
  # IO.new delegates to VfsRealIO. These instances methods
  # are only called through File objects.
  #
  module ThinIODelegatorMethods
    # Instance methods
    def initialize(fs_io_obj, parsed_args)
      @fs_io_obj       = fs_io_obj
      @size            = @fs_io_obj.size
      @start_byte_addr = 0
      @end_byte_addr   = @size - 1

      @parsed_args = parsed_args
      @seek_pos    = @parsed_args.append? ? @size : 0 # The current byte position within the file.

      @binary_encoding   = Encoding.find("ASCII-8BIT")
      @autoclose         = @parsed_args.autoclose?

      bio_init

      enable_finalizer if @autoclose
    end

    def re_initialize(io_obj)
      close
      io_obj.flush

      @fs_io_obj   = io_obj.instance_variable_get(:@fs_io_obj)
      @parsed_args = io_obj.instance_variable_get(:@parsed_args)
      @seek_pos    = io_obj.instance_variable_get(:@seek_pos)

      @size            = @fs_io_obj.size
      @start_byte_addr = 0
      @end_byte_addr   = @size - 1
      @autoclose       = @parsed_args.autoclose?

      bio_reinit(io_obj)

      enable_finalizer if @autoclose
    end

    def enable_finalizer
      # XXX ObjectSpace.define_finalizer(self, self.class.finalize(fs_file_obj))
    end

    def disable_finalizer
      # XXX
    end

    def self.finalize(obj)
      proc { obj.close }
    end

    def autoclose=(bool)
      file_open
      initial_val = @autoclose
      if (@autoclose = bool ? true : false)
        enable_finalizer if initial_val == false
      else
        disable_finalizer if initial_val == true
      end
      bool
    end

    def autoclose?
      file_open
      @autoclose
    end

    def binmode
      file_open
      @parsed_args.binmode
      self
    end

    def binmode?
      file_open
      @parsed_args.binmode?
    end

    def close
      file_open
      @io_buffer.flush
      @fs_io_obj.close
      @parsed_args.close
      @autoclose = false
      nil
    end

    def close_on_exec?
      file_open
      @fs_io_obj.close_on_exec?
    end

    def close_on_exec=(bool)
      @fs_io_obj.close_on_exec = bool
    end

    def close_read
      file_open
      raise IOError, "closing non-duplex IO for reading" unless @parsed_args.rdonly?
      @parsed_args.close_read
      @fs_io_obj.close_read
    end

    def close_write
      file_open
      raise IOError, "closing non-duplex IO for writing" unless @parsed_args.wronly?
      @parsed_args.close_write
      @fs_io_obj.close_write
    end

    def closed?
      @parsed_args.closed?
    end

    def eof
      file_open && for_reading
      @seek_pos > @end_byte_addr
    end
    alias_method :eof?, :eof

    def external_encoding
      file_open
      @parsed_args.external_encoding
    end

    def fcntl(cms, arg)
      file_open
      @fs_io_obj.fcntl(cms, arg)
    end

    def fdatasync
      file_open
      @fs_io_obj.fdatasync
    end

    def fileno
      file_open
      @fs_io_obj.fileno
    end
    alias_method :to_i, :fileno

    def flush
      file_open
      @io_buffer.flush
      @fs_io_obj.flush
      self
    end

    def fsync
      file_open
      @fs_io_obj.fsync
    end

    def internal_encoding
      file_open
      @parsed_args.internal_encoding
    end

    def ioctl(cmd, arg)
      file_open
      @fs_io_obj.ioctl(cmd, arg)
    end

    def isatty
      file_open
      @fs_io_obj.isatty
    end
    alias_method :tty?, :isatty

    def pid
      file_open
      @fs_io_obj.pid
    end

    def pos
      file_open
      @seek_pos
    end
    alias_method :tell, :pos

    def pos=(p)
      file_open
      raise SystemCallError.new(p.to_s, Errno::EINVAL::Errno) if p < 0
      @seek_pos = p
    end

    def readpartial(limit, result = "")
      file_open && for_reading
      @fs_io_obj.readpartial(limit, result)
    end

    def reopen(*args)
      raise ArgumentError, "wrong number of arguments (#{args.length} for 1..2)" if args.empty? || args.length > 2
      if args[0].respond_to?(:to_str)
        VFile.new(*args).__getobj__
      elsif args[0].respond_to?(:__getobj__)
        args[0].__getobj__.dup
      else
        args[0]
      end
    end

    def rewind
      file_open
      @seek_pos = 0
    end

    def seek(offset, whence = IO::SEEK_SET)
      file_open
      sysseek(offset, whence)
      0
    end

    def set_encoding(*args)
      file_open
      @parsed_args.set_encoding(*args)
      self
    end

    def stat
      file_open
      @fs_io_obj.stat # XXX wrap in VirtFS::Stat
    end

    def sysread(len, buffer = nil)
      file_open && for_reading && not_at_eof
      rv = @fs_io_obj.raw_read(@seek_pos, len)
      @seek_pos += rv.bytesize
      buffer.replace(rv) unless buffer.nil?
      rv
    end

    def sysseek(offset, whence = IO::SEEK_SET)
      file_open
      new_pos  = case whence
                 when IO::SEEK_CUR then @seek_pos + offset
                 when IO::SEEK_END then @size + offset
                 when IO::SEEK_SET then @start_byte_addr + offset
                 end

      raise SystemCallError.new(offset.to_s, Errno::EINVAL::Errno) if new_pos < 0
      @seek_pos = new_pos
    end

    def syswrite(buf)
      file_open && for_writing
      rv = @fs_io_obj.raw_write(@seek_pos, buf)
      update_write_pos(rv)
      rv
    end

    def to_io
      self
    end

    def write_nonblock(buf)
      file_open && for_writing
      @fs_io_obj.write_nonblock(buf)
    end

    private

    def file_open
      raise IOError, "closed stream" if closed?
      true
    end

    def for_reading
      raise IOError, "not opened for reading" unless @parsed_args.read?
      true
    end

    def for_writing
      raise IOError, "not opened for writing" unless @parsed_args.write?
      true
    end

    def not_at_eof
      raise EOFError, "end of file reached" if eof?
      true
    end

    def update_write_pos(len)
      @seek_pos += len
      return if @seek_pos <= @size
      @size = @seek_pos
      @end_byte_addr = @seek_pos - 1
    end
  end
end
