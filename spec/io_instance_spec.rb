require 'spec_helper'
require 'fcntl'

describe VirtFS::VIO, "(#{$fs_interface} interface)" do
  before(:all) do
    @start_marker = "START OF FILE:\n"
    @end_marker   = ":END OF FILE"
    @data1        = "0123456789"
    @data2        = "abcdefghijklmnopqrstuvwzyz\n"

    @temp_file    = Tempfile.new("VirtFS-IO")
    @temp_file.write(@start_marker)
    (0..9).each do
      @temp_file.write(@data1)
      @temp_file.write(@data2)
    end
    @temp_file.write(@end_marker)
    @temp_file.close

    @full_path  = @temp_file.path
    @file_size  = VfsRealFile.size(@full_path)

    @temp_write = Tempfile.new("VirtFS-IO")
    @temp_write.close
    @write_file_path = @temp_write.path

    @temp_rdwr = Tempfile.new("VirtFS-IO")
    @temp_rdwr.close
    @rdwr_file_path = @temp_rdwr.path

    @binary_encoding  = Encoding.find("ASCII-8BIT")
  end

  before(:each) do
    reset_context

    @root      = File::SEPARATOR
    @native_fs = nativefs_class.new
    VirtFS.mount(@native_fs, @root)

    @vfile_read_obj  = VirtFS::VFile.new(@full_path, "r")
    @vfile_write_obj = VirtFS::VFile.new(@write_file_path, "w")
    @vfile_rdwr_obj  = VirtFS::VFile.new(@rdwr_file_path, "w+")
  end

  after(:each) do
    @vfile_read_obj.close  unless @vfile_read_obj.closed?
    @vfile_write_obj.close unless @vfile_write_obj.closed?
    @vfile_rdwr_obj.close  unless @vfile_rdwr_obj.closed?
    VirtFS.umount(@root)
  end

  describe "#autoclose=" do
    it "should change the value from true to false" do
      expect(@vfile_read_obj.autoclose?).to be true
      @vfile_read_obj.autoclose = false
      expect(@vfile_read_obj.autoclose?).to be false
    end

    it "should change the value from true to false - given a 'falsey' value" do
      expect(@vfile_read_obj.autoclose?).to be true
      @vfile_read_obj.autoclose = nil
      expect(@vfile_read_obj.autoclose?).to be false
    end

    it "should change the value from false to true" do
      @vfile_read_obj.autoclose = false
      expect(@vfile_read_obj.autoclose?).to be false
      @vfile_read_obj.autoclose = true
      expect(@vfile_read_obj.autoclose?).to be true
    end

    it "should change the value from false to true - given a 'truthy' value" do
      @vfile_read_obj.autoclose = false
      expect(@vfile_read_obj.autoclose?).to be false
      @vfile_read_obj.autoclose = "???"
      expect(@vfile_read_obj.autoclose?).to be true
    end
  end

  describe "#autoclose?" do
    it "should return the default value of true" do
      expect(@vfile_read_obj.autoclose?).to be true
    end
  end

  describe "#binmode" do
    it "should return the IO object" do
      expect(@vfile_read_obj.binmode).to eq(@vfile_read_obj)
    end

    it "should set binmode to true" do
      expect(@vfile_read_obj.binmode?).to be false
      @vfile_read_obj.binmode
      expect(@vfile_read_obj.binmode?).to be true
    end

    it "should set the external_encoding to binary encoding" do
      expect(@vfile_read_obj.external_encoding).to_not eq(@binary_encoding)
      @vfile_read_obj.binmode
      expect(@vfile_read_obj.external_encoding).to eq(@binary_encoding)
    end

    it "should set the internal_encoding to nil" do
      # XXX Real File does not seem to change the internal encoding.
      # @vfile_read_obj.set_encoding(":UTF-8")
      # expect(@vfile_read_obj.internal_encoding).to_not be_nil
      @vfile_read_obj.binmode
      expect(@vfile_read_obj.internal_encoding).to be_nil
    end
  end

  describe "#binmode?" do
    it "should return false by default" do
      expect(@vfile_read_obj.binmode?).to be false
    end

    it "should return true when in binmode" do
      expect(@vfile_read_obj.binmode?).to be false
      @vfile_read_obj.binmode
      expect(@vfile_read_obj.binmode?).to be true
    end
  end

  describe "#close" do
    it "should return nil" do
      expect(@vfile_read_obj.close).to be_nil
    end

    context "should cause subsequent operations to raise IOError" do
      {
        :<<                => ["hello"],
        :autoclose=        => [true],
        :autoclose?        => [],
        :binmode           => [],
        :binmode?          => [],
        :close             => [],
        :close_on_exec?    => [],
        :close_on_exec=    => [true],
        :close_read        => [],
        :close_write       => [],
        :each              => [],
        :each_byte         => [],
        :each_char         => [],
        :each_codepoint    => [],
        :eof               => [],
        :external_encoding => [],
        :fcntl             => [0, 1],
        :fdatasync         => [],
        :fileno            => [],
        :flush             => [],
        :fsync             => [],
        :getbyte           => [],
        :getc              => [],
        :gets              => [],
        :internal_encoding => [],
        :ioctl             => [0, 1],
        :isatty            => [],
        :lineno            => [],
        :lineno=           => [10],
        :pid               => [],
        :pos               => [],
        :pos=              => [0],
        :print             => ["string"],
        :printf            => ["format"],
        :putc              => ["X"],
        :puts              => ["string"],
        :read              => [10],
        :readbyte          => [],
        :readchar          => [],
        :readline          => [],
        :readlines         => [],
        :readpartial       => [10],
        :rewind            => [],
        :seek              => [0],
        :set_encoding      => ["encoding"],
        :stat              => [],
        :sync              => [],
        :sync=             => [true],
        :sysread           => [10],
        :sysseek           => [0],
        :syswrite          => ["hello"],
        :ungetbyte         => ["x"],
        :ungetc            => ["X"],
        :write             => ["string"],
        :write_nonblock    => ["hello"],
      }.each do |method, args|
        it "should cause subsequent '#{method}' call to raise IOError" do
          @vfile_read_obj.close
          expect { @vfile_read_obj.send(method, *args) {} }.to raise_error(IOError, "closed stream")
        end
      end
    end
  end

  describe "#close_on_exec?" do
    it "should return true by default" do
      expect(@vfile_read_obj.close_on_exec?).to be true
    end

    it "should return false when set to false" do
      @vfile_read_obj.close_on_exec = false
      expect(@vfile_read_obj.close_on_exec?).to be false
    end
  end

  describe "#close_on_exec=" do
    it "should change the close_on_exec setting" do
      coe = @vfile_read_obj.close_on_exec?
      @vfile_read_obj.close_on_exec = !coe
      expect(@vfile_read_obj.close_on_exec?).to be !coe
    end
  end

  describe "#close_read" do
    it "should raise IOError when called on a closed file" do
      @vfile_read_obj.close
      expect do
        @vfile_read_obj.close_read
      end.to raise_error(IOError, "closed stream")
    end

    it "should raise IOError when called on a regular file opend rdwr" do
      expect do
        @vfile_rdwr_obj.close_read
      end.to raise_error(IOError, "closing non-duplex IO for reading")
    end

    it "should raise IOError when called on a file not open for reading" do
      expect do
        @vfile_write_obj.close_read
      end.to raise_error(IOError, "closing non-duplex IO for reading")
    end

    it "should close a file that's only open for reading" do
      expect(@vfile_read_obj.close_read).to be nil
      expect(@vfile_read_obj.closed?).to be true
    end
  end

  describe "#close_write" do
    it "should raise IOError when called on a closed file" do
      @vfile_read_obj.close
      expect do
        @vfile_read_obj.close_write
      end.to raise_error(IOError, "closed stream")
    end

    it "should raise IOError when called on a regular file opend rdwr" do
      expect do
        @vfile_rdwr_obj.close_write
      end.to raise_error(IOError, "closing non-duplex IO for writing")
    end

    it "should raise IOError when called on a file not open for writing" do
      expect do
        @vfile_read_obj.close_write
      end.to raise_error(IOError, "closing non-duplex IO for writing")
    end

    it "should close a file that's only open for writing" do
      expect(@vfile_write_obj.close_write).to be nil
      expect(@vfile_write_obj.closed?).to be true
    end
  end

  describe "#closed?" do
    it "should return false if the file is open" do
      expect(@vfile_read_obj.closed?).to be false
    end

    it "should return true if the file is closed" do
      @vfile_read_obj.close
      expect(@vfile_read_obj.closed?).to be true
    end
  end

  describe "#fcntl" do
    it "should return the requested value" do
      expect(@vfile_read_obj.fcntl(Fcntl::F_GETFD, nil)).to be_kind_of(Integer)
    end
  end

  describe "#fileno" do
    it "should return the integer file number" do
      expect(@vfile_read_obj.fileno).to be_kind_of(Integer)
    end
  end

  describe "#ioctl" do
    it "should do something"
  end

  describe "#isatty" do
    it "should return false for a regular file" do
      expect(@vfile_read_obj.isatty).to be false
    end
  end

  describe "#pid" do
    it "should return nil for a regular file" do
      expect(@vfile_read_obj.pid).to be nil
    end
  end

  describe "#reopen" do
    it "should return the IO object" do
      expect(@vfile_read_obj.reopen(@vfile_write_obj)).to eq(@vfile_read_obj)
    end

    it "should take on the attributes of the new IO stream - given IO object" do
      expect(@vfile_read_obj.path).to_not eq(@vfile_write_obj.path)
      expect(@vfile_read_obj.size).to_not eq(@vfile_write_obj.size)

      @vfile_read_obj.reopen(@vfile_write_obj)

      expect(@vfile_read_obj.path).to eq(@vfile_write_obj.path)
      expect(@vfile_read_obj.size).to eq(@vfile_write_obj.size)
    end

    it "should take on the attributes of the new IO stream - given open args" do
      expect(@vfile_read_obj.path).to_not eq(@vfile_write_obj.path)
      expect(@vfile_read_obj.size).to_not eq(@vfile_write_obj.size)

      @vfile_read_obj.reopen(@write_file_path, "w")

      expect(@vfile_read_obj.path).to eq(@vfile_write_obj.path)
      expect(@vfile_read_obj.size).to eq(@vfile_write_obj.size)
    end

    it "should read the same data as the standard File#read - given IO object" do
      rfile_obj = VfsRealFile.new(@full_path, "r")
      @vfile_write_obj.reopen(@vfile_read_obj)

      read_size = 20
      loop do
        rv1 = @vfile_write_obj.read(read_size)
        rv2 = rfile_obj.read(read_size)
        expect(rv1).to eq(rv2)
        break if rv1.nil? || rv1.empty?
      end
    end

    it "should read the same data as the standard File#read - given open args" do
      rfile_obj = VfsRealFile.new(@full_path, "r")
      @vfile_write_obj.reopen(@full_path, "r")

      read_size = 20
      loop do
        rv1 = @vfile_write_obj.read(read_size)
        rv2 = rfile_obj.read(read_size)
        expect(rv1).to eq(rv2)
        break if rv1.nil? || rv1.empty?
      end
    end
  end

  describe "#stat" do
    it "should return the stat information for the regular file" do
      expect(@vfile_write_obj.stat.symlink?).to be false
    end
  end

  describe "#sysread" do
    before(:each) do
      @rfile_obj = VfsRealFile.new(@full_path, "r")
    end

    after(:each) do
      @rfile_obj.close
    end

    it "should read the number of bytes requested - when EOF not reached" do
      read_size = @file_size / 2
      rv = @vfile_read_obj.sysread(read_size)
      expect(rv.bytesize).to eq(read_size)
    end

    it "should read data into buffer, when supplied" do
      read_size = @file_size / 2
      rbuf = ""
      rv = @vfile_read_obj.sysread(read_size, rbuf)
      expect(rv).to eq(rbuf)
    end

    it "should read at most, the size of the file" do
      rv = @vfile_read_obj.sysread(@file_size + 100)
      expect(rv.bytesize).to eq(@file_size)
    end

    it "should raise EOFError when attempting to read at EOF" do
      @vfile_read_obj.sysread(@file_size)
      expect do
        @vfile_read_obj.sysread(@file_size)
      end.to raise_error(
        EOFError, "end of file reached"
      )
    end

    it "should read the same data as the standard File#sysread" do
      read_size = 20
      loop do
        begin
          rv1 = @vfile_read_obj.sysread(read_size)
          rv2 = @rfile_obj.sysread(read_size)
        rescue EOFError
          break
        end
        expect(rv1).to eq(rv2)
      end
    end
  end

  describe "#sysseek" do
    it "should raise Errno::EINVAL when attempting to seek before the beginning of the file" do
      expect do
        @vfile_read_obj.sysseek(-10, IO::SEEK_CUR)
      end.to raise_error(
        Errno::EINVAL, /Invalid argument/
      )
    end

    it "should return the new offset into the file - IO::SEEK_SET" do
      offset = @file_size / 2
      pos = @vfile_read_obj.sysseek(offset, IO::SEEK_SET)
      expect(pos).to eq(offset)
    end

    it "should return the new offset into the file - IO::SEEK_CUR" do
      offset = @file_size / 2
      @vfile_read_obj.sysseek(offset, IO::SEEK_SET)
      pos = @vfile_read_obj.sysseek(-10, IO::SEEK_CUR)
      expect(pos).to eq(offset - 10)
    end

    it "should return the new offset into the file - IO::SEEK_END" do
      pos = @vfile_read_obj.sysseek(-10, IO::SEEK_END)
      expect(pos).to eq(@file_size - 10)
    end

    it "should change the read position within the file - IO::SEEK_SET" do
      @vfile_read_obj.sysseek(@start_marker.bytesize, IO::SEEK_SET)
      rv = @vfile_read_obj.sysread(@data1.bytesize)
      expect(rv).to eq(@data1)
    end

    it "should change the read position within the file - IO::SEEK_CUR" do
      @vfile_read_obj.sysseek(@start_marker.bytesize, IO::SEEK_SET)
      @vfile_read_obj.sysseek(@data1.bytesize, IO::SEEK_CUR)
      rv = @vfile_read_obj.sysread(@data2.bytesize)
      expect(rv).to eq(@data2)
    end

    it "should change the read position within the file - IO::SEEK_END" do
      @vfile_read_obj.sysseek(-@end_marker.bytesize, IO::SEEK_END)
      rv = @vfile_read_obj.sysread(@end_marker.bytesize)
      expect(rv).to eq(@end_marker)
    end
  end

  describe "#syswrite" do
    it "should return the number of bytes written" do
      write_str = "0123456789"
      expect(@vfile_write_obj.syswrite(write_str)).to eq(write_str.bytesize)
    end

    it "should update the current file position" do
      write_str = "0123456789"
      last_pos = @vfile_write_obj.pos
      (0..9).each do
        @vfile_write_obj.syswrite(write_str)
        pos = @vfile_write_obj.pos
        expect(pos).to eq(last_pos + write_str.bytesize)
        last_pos = pos
      end
    end

    it "should update the size of the file" do
      write_str = "0123456789"
      last_size = @vfile_write_obj.size
      (0..9).each do
        @vfile_write_obj.syswrite(write_str)
        size = @vfile_write_obj.size
        expect(size).to eq(last_size + write_str.bytesize)
        last_size = size
      end
    end

    it "should write data that's readable" do
      write_str = "0123456789"
      (0..9).each do
        @vfile_write_obj.syswrite(write_str)
      end

      @vfile_write_obj.close
      @vfile_write_obj = VirtFS::VFile.new(@write_file_path, "r")

      (0..9).each do
        expect(@vfile_write_obj.sysread(write_str.bytesize)).to eq(write_str)
      end

      expect do
        @vfile_write_obj.sysread(write_str.bytesize)
      end.to raise_error(
        EOFError, "end of file reached"
      )
    end
  end

  describe "#to_io" do
    it "should return itself" do
      @vfile_read_obj = VirtFS::VFile.new(@full_path, "r")
      expect(@vfile_read_obj.to_io).to eq(@vfile_read_obj)
    end
  end
end
