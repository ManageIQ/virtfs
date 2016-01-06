module VirtFS
  module ThinIODelegatorMethods
    attr_reader :min_read_buf_sz, :read_buffer, :end_byte_addr, :fs_io_obj

    MIN_READ_BUF_SZ = 1024 * 32
    MAX_CHAR_LEN    = 8

    def min_read_buf_sz=(val)
      @min_read_buf_sz = val
      @io_buffer.min_buf_sz = val
    end
    private :min_read_buf_sz=

    def <<(obj)
      file_open && for_writing
      write(obj.to_s)
      self
    end

    def bytes # deprecated
      to_enum(:enumerate_til_eof, :getbyte, nil, nil)
    end

    def chars # deprecated
      to_enum(:enumerate_til_eof, :getc, nil, nil)
    end

    def each(*args, &block)
      sep, lim = separator_limit_args(args)
      # block = block_given? ? Proc.new : nil
      each_common(sep, lim, block)
    end
    alias_method :each_line, :each

    def each_common(sep, lim, block)
      return enumerate_return(:read, self, block)                           if sep.nil?
      return enumerate_return(:read_paragraph, self, lim, block)            if sep.empty?
      return enumerate_return(:read_line_with_limit, self, sep, lim, block) if lim > 0
      enumerate_return(:read_line, self, sep, block)
    end

    def each_byte
      block = block_given? ? Proc.new : nil
      enumerate_return(:getbyte, self, block)
    end

    def each_char
      block = block_given? ? Proc.new : nil
      enumerate_return(:getc, self, block)
    end

    def each_codepoint
      block = block_given? ? Proc.new : nil
      enumerate_return(:codepoint, self, block)
    end
    alias_method :codepoints, :each_codepoint

    def codepoint
      file_open && for_reading
      return nil if eof?
      rv = @io_buffer.get_char(@seek_pos)
      @seek_pos += rv.bytesize
      rv.ord
    end
    private :codepoint

    def getbyte
      file_open && for_reading
      return nil if eof?
      rv = @io_buffer.get_byte(@seek_pos)
      @seek_pos += 1
      rv
    end

    def getc
      file_open && for_reading
      return nil if eof?
      rv = @io_buffer.get_char(@seek_pos)
      @seek_pos += rv.bytesize
      rv.encode!(internal_encoding) if internal_encoding
      rv
    end

    def gets(*args)
      file_open && for_reading
      return nil if eof?
      sep, lim = separator_limit_args(args)
      return read                           if sep.nil?
      return read_paragraph(lim)            if sep.empty?
      return read_line_with_limit(sep, lim) if lim > 0
      read_line(sep)
    end

    def lineno
      file_open && for_reading
      @lineno
    end

    def lineno=(ln)
      file_open && for_reading
      raise TypeError, "no implicit conversion from #{ln.class.name} to integer" unless ln.respond_to?(:to_int)
      @lineno = ln
    end

    def lines(*args) # deprecated
      to_enum(:enumerate_til_eof, :gets, self, *args, nil)
    end

    def print(*args)
      file_open && for_writing
      write(objects_to_str(args, true, $_, $\, $,))
      nil
    end

    def printf(format_str, *args)
      file_open && for_writing
      write(format(format_str, *args))
      nil
    end

    def putc(obj)
      file_open && for_writing
      c = obj.is_a?(Integer) ? obj.chr : obj.to_s[0]
      write(c)
      obj
    end

    def puts(*args)
      file_open && for_writing
      write(objects_to_str(args, false, $/, $/, $/))
      nil
    end

    def read(len = nil, buffer = nil)
      file_open && for_reading
      if len.nil?
        return "" if eof?
        len = @size
        encode = true
      else
        return nil if eof?
        encode = false
      end

      rv = @io_buffer.get_str(@seek_pos, len)
      @seek_pos += rv.bytesize

      if encode
        rv.force_encoding(external_encoding) if external_encoding
        rv.encode!(internal_encoding)        if internal_encoding
      end
      buffer.replace(rv) unless buffer.nil?
      rv
    end

    def readbyte
      file_open && for_reading && not_at_eof
      getbyte
    end

    def readchar
      file_open && for_reading && not_at_eof
      getc
    end

    def readline(*args)
      file_open && for_reading && not_at_eof
      gets(*args)
    end

    def readlines(*args)
      file_open && for_reading
      each(*args).to_a
    end

    def sync
      file_open
      @io_buffer.sync
    end

    def sync=(bool)
      file_open
      @io_buffer.sync = bool
    end

    def ungetbyte(val)
      file_open && for_reading
      str = val.respond_to?(:to_int) ? val.to_int.chr : val.to_str
      @io_buffer.cover_range(@seek_pos, 1)
      @io_buffer.truncate_left(@seek_pos)
      len = @io_buffer.prepend_bytes(str)
      @seek_pos -= len
      nil
    end

    def ungetc(string)
      file_open && for_reading
      @io_buffer.cover_range(@seek_pos, 1)
      @io_buffer.truncate_left(@seek_pos)
      len = @io_buffer.prepend_str(string)
      @seek_pos -= len
      nil
    end

    def write(buf)
      file_open && for_writing
      buf = buf.dup
      buf.encode!(external_encoding) if external_encoding
      buf.force_encoding(@binary_encoding)
      rv = @io_buffer.write_to_buffer(@seek_pos, buf)
      update_write_pos(rv)
      rv
    end

    private

    #
    # Called from initialize()
    #
    def bio_init
      @lineno          = 0 # The current line number - based on gets calls.
      @min_read_buf_sz = MIN_READ_BUF_SZ
      @io_buffer       = IOBuffer.new(self, @min_read_buf_sz)
    end

    def bio_reinit(io_obj)
      @lineno    = io_obj.instance_variable_get(:@lineno)
      @io_buffer = IOBuffer.new(self, @min_read_buf_sz)
    end

    #
    # Return at most lim bytes, or up to end of line.
    #
    def read_line_with_limit(sep, lim)
      file_open
      @io_buffer.cover_range(@seek_pos, lim)
      offset = @io_buffer.buf_offset(@seek_pos)
      if (eol_pos = @io_buffer.buffer.index(sep, offset))
        eol_len = eol_pos - offset + sep.bytesize - 1
        @lineno += 1
      else
        eol_len = lim + 1
        @lineno += 1 if eof?
      end
      read_from_buf([lim, eol_len, @io_buffer.available_bytes(@seek_pos)].min)
    end

    #
    # Return up to end of line, or end of file.
    #
    def read_line(sep)
      file_open
      @io_buffer.cover_range(@seek_pos, 1)
      offset = @io_buffer.buf_offset(@seek_pos)
      while (eol_pos = @io_buffer.buffer.index(sep, offset)).nil?
        break if @io_buffer.at_eof?
        @io_buffer.extend_right(@min_read_buf_sz)
      end

      @lineno += 1
      return read_from_buf(@io_buffer.available_bytes(@seek_pos)) unless eol_pos
      read_from_buf(eol_pos - offset + sep.bytesize) if eol_pos
    end

    #
    # Return len bytes from the buffer, adjusting the current position.
    #
    def read_from_buf(len)
      rv = @io_buffer.get_str(@seek_pos, len)
      @seek_pos += len
      rv.force_encoding(external_encoding) if external_encoding
      rv.encode!(internal_encoding)        if internal_encoding
      rv
    end

    def enumerate_til_eof(meth, rv, *args, block)
      if block
        block.call(send(meth, *args)) until eof?
      else
        yield(send(meth, *args)) until eof?
      end
      rv
    end

    def enumerate_return(meth, ret, *args, block)
      return to_enum(:enumerate_til_eof, meth, ret, *args, block) if block.nil?
      enumerate_til_eof(meth, ret, *args, block)
    end

    #
    # Parse separator and limit args.
    #
    def separator_limit_args(args)
      case args.length
      when 0
        return encode_separator($/), 0
      when 1
        return encode_separator($/), args[0].to_int if args[0].respond_to?(:to_int)
        return encode_separator(args[0]), 0
      when 2
        return encode_separator(args[0]), args[1]
      else
        raise ArgumentError, "wrong number of arguments (3 for 0..2)"
      end
    end

    def encode_separator(sep)
      return nil if sep.nil?
      sep = sep.encode(external_encoding)
      sep.force_encoding(@binary_encoding)
    end

    def objects_to_str(args, dup_sep_ok = true, default = nil, ors = nil, ofs = nil)
      ret_str = ""
      if args.empty?
        ret_str << default if default
      else
        first_obj = true
        args.each do |obj|
          add_sep(ret_str, ofs, dup_sep_ok) unless first_obj
          ret_str << obj.to_s
          first_obj = false
        end
      end
      add_sep(ret_str, ors, dup_sep_ok)
      ret_str
    end

    def add_sep(str, sep, dup_sep_ok)
      return unless sep
      return if !dup_sep_ok && str.end_with?(sep)
      str << sep
    end
  end
end
