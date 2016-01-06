module VirtFS
  class BlockIO
    MIN_BLOCKS_TO_CACHE = 64

    def initialize(io_obj)
      @io_obj          = io_obj
      @block_size      = @io_obj.block_size   # Size of block in bytes
      @size            = @io_obj.size         # Size of file in bytes
      @size_in_blocks  = @size / @block_size  # Size of file in blocks
      @start_byte_addr = 0
      @end_byte_addr   = @size - 1
      @lba_end         = @size_in_blocks - 1
      @seek_pos        = 0
      @cache_range     = Range.new(-1, -1)
    end

    def read(len)
      return nil if @seek_pos >= @end_byte_addr
      len = @end_byte_addr - @seek_pos if (@seek_pos + len) > @end_byte_addr

      start_sector, start_offset = @seek_pos.divmod(@block_size)
      end_sector = (@seek_pos + len - 1) / @block_size
      num_sector = end_sector - start_sector + 1

      rbuf = bread_cached(start_sector, num_sector)
      @seek_pos += len

      rbuf[start_offset, len]
    end

    def write(buf, len)
      return nil if @seek_pos >= @end_byte_addr
      len = @end_byte_addr - @seek_pos if (@seek_pos + len) > @end_byte_addr

      start_sector, start_offset = @seek_pos.divmod(@block_size)
      end_sector = (@seek_pos + len - 1) / @block_size
      num_sector = end_sector - start_sector + 1

      rbuf = bread(start_sector, num_sector)
      rbuf[start_offset, len] = buf[0, len]

      bwrite(start_sector, num_sector, rbuf)
      @seek_pos += len

      len
    end

    def seek(amt, whence = IO::SEEK_SET)
      case whence
      when IO::SEEK_CUR
        @seek_pos += amt
      when IO::SEEK_END
        @seek_pos = @end_byte_addr + amt
      when IO::SEEK_SET
        @seek_pos = amt + @start_byte_addr
      end
      @seek_pos
    end

    def size
      @size
    end

    def close
      @io_obj.close
    end

    def bread(start_sector, num_sectors)
      # $log.debug "RawBlockIO.bread: start_sector = #{start_sector}, num_sectors = #{num_sectors}, @lba_end = #{@lba_end}"
      return nil if start_sector > @lba_end
      num_sectors = @size_in_blocks - start_sector if (start_sector + num_sectors) > @size_in_blocks
      @io_obj.raw_read(start_sector * @block_size, num_sectors * @block_size)
    end

    def bwrite(start_sector, num_sectors, buf)
      return nil if start_sector > @lba_end
      num_sectors = @size_in_blocks - start_sector if (start_sector + num_sectors) > @size_in_blocks
      @io_obj.raw_write(buf, start_sector * @block_size, num_sectors * @block_size)
    end

    def bread_cached(start_sector, num_sectors)
      # $log.debug "RawBlockIO.bread_cached: start_sector = #{start_sector}, num_sectors = #{num_sectors}"
      if !@cache_range.include?(start_sector) || !@cache_range.include?(start_sector + num_sectors - 1)
        sectors_to_read = [MIN_BLOCKS_TO_CACHE, num_sectors].max
        @cache = bread(start_sector, sectors_to_read)
        sectors_read   = @cache.length / @block_size
        end_sector     = start_sector + sectors_read - 1
        @cache_range   = Range.new(start_sector, end_sector)
      end

      sector_offset = start_sector  - @cache_range.first
      buffer_offset = sector_offset * @block_size
      length        = num_sectors   * @block_size
      # $log.debug "RawBlockIO.bread_cached: buffer_offset = #{buffer_offset}, length = #{length}"

      @cache[buffer_offset, length]
    end
  end
end
