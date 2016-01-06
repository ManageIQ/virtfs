module VirtFS
  class IOBuffer
    attr_accessor :min_buf_sz, :external_encoding, :sync
    attr_reader   :buffer, :range

    MAX_CHAR_LEN = 8

    def initialize(io_obj, min_buf_sz)
      @io_obj            = io_obj
      @min_buf_sz        = min_buf_sz
      @binary_encoding   = Encoding.find("ASCII-8BIT")
      @buffer            = ""
      @range             = ByteRange.new
      @write_range       = ByteRange.new
      @sync              = false
    end

    def cover_range(pos, len)
      len = adjust_len_to_eof(len, pos)
      end_pos = pos + len - 1

      return if @range.include?(pos) && @range.include?(end_pos)

      if @range.include?(pos)
        truncate_left(pos)
        extend_right(len)
        return
      end

      flush # If write data, flush.
      raw_read_len = adjust_len_to_eof([@min_buf_sz, len].max, pos)
      @buffer = @io_obj.fs_io_obj.raw_read(pos, raw_read_len)
      @range.set(pos, pos + raw_read_len - 1)
    end

    def extend_right(len)
      raw_read_len = adjust_len_to_eof([@min_buf_sz, len].max, @range.last)
      rv = @io_obj.fs_io_obj.raw_read(@range.last + 1, raw_read_len)
      @buffer << rv
      @range.last += raw_read_len
    end

    def truncate_left(pos)
      flush if @write_range.include?(pos) # If pos is within write_range, flush.
      offset = buf_offset(pos)
      return if offset == 0
      @buffer = @buffer[offset..-1]
      @range.first += offset
    end

    def prepend_bytes(str)
      str = str.dup
      str.force_encoding(@binary_encoding)
      prepend(str)
    end

    def prepend_str(str)
      str = str.dup
      str.encode!(@io_obj.external_encoding) if @io_obj.external_encoding
      str.force_encoding(@binary_encoding)
      prepend(str)
    end

    # for unget, data does not get written - never in write_range.
    def prepend(str)
      @buffer.insert(0, str)
      @range.first -= str.bytesize
      str.bytesize
    end

    def write_to_buffer(pos, str)
      len = str.bytesize
      end_pos = pos + len - 1
      flush unless @write_range.contiguous?(pos, end_pos)
      @write_range.expand(pos, end_pos)
      @range.expand(@write_range)
      @buffer[buf_offset(pos), len] = str
      flush if @sync
      len
    end

    def adjust_len_to_eof(len, pos)
      return @io_obj.end_byte_addr - pos + 1 if (pos + len - 1) > @io_obj.end_byte_addr
      len
    end

    def get_byte(pos)
      cover_range(pos, 1)
      @buffer.getbyte(buf_offset(pos))
    end

    def get_char(pos)
      max_char_len = adjust_len_to_eof(MAX_CHAR_LEN, pos)
      cover_range(pos, max_char_len)
      offset = buf_offset(pos)
      (1..max_char_len).each do |len|
        char = @buffer[offset, len]
        char.force_encoding(@io_obj.external_encoding)
        return char if char.valid_encoding?
      end
      raise "Invalid byte sequence"
    end

    def get_str(pos, len)
      len = adjust_len_to_eof(len, pos)
      cover_range(pos, len)
      @buffer[buf_offset(pos), len]
    end

    def flush
      return if @write_range.empty?
      offset = buf_offset(@write_range.first)
      length = @write_range.length
      rv = @io_obj.fs_io_obj.raw_write(@write_range.first, @buffer[offset, length])
      @write_range.clear
      rv
    end

    def available_bytes(pos)
      @range.last - pos + 1
    end

    def at_eof?
      @range.last >= @io_obj.end_byte_addr
    end

    def buf_offset(pos)
      pos - @range.first
    end
  end
end
