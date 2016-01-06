require 'spec_helper'

describe VirtFS::VIO, "(#{$fs_interface} interface)" do
  before(:all) do
    @data_dir        = VfsRealFile.join(__dir__, "data")
    @utf_8_filename  = VfsRealFile.join(@data_dir, "UTF-8-data.txt")
    @utf_16_filename = VfsRealFile.join(@data_dir, "UTF-16LE-data.txt")

    @start_marker = "START OF FILE:\n"
    @end_marker   = ":END OF FILE"
    @data1        = "0123456789"
    @data2        = "abcdefghijklmnopqrstuvwzyz\n"

    @default_encoding = Encoding.default_external
    @binary_encoding  = Encoding.find("ASCII-8BIT")
  end

  before(:each) do
    reset_context

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

    @root      = File::SEPARATOR
    @native_fs = nativefs_class.new
    VirtFS.mount(@native_fs, @root)

    @vfile_read_obj  = VirtFS::VFile.new(@full_path, "r")
    @vfile_write_obj = VirtFS::VFile.new(@write_file_path, "w")
  end

  after(:each) do
    @vfile_read_obj.close  unless @vfile_read_obj.closed?
    @vfile_write_obj.close unless @vfile_write_obj.closed?
    VirtFS.umount(@root)
  end

  describe "#<<" do
    it "should return the IO object" do
      expect(@vfile_write_obj << "hello").to eq(@vfile_write_obj)
    end

    it "should update the current file position" do
      write_str = "0123456789"
      last_pos = @vfile_write_obj.pos
      (0..9).each do
        @vfile_write_obj << write_str
        pos = @vfile_write_obj.pos
        expect(pos).to eq(last_pos + write_str.bytesize)
        last_pos = pos
      end
    end

    it "should update the size of the file" do
      write_str = "0123456789"
      last_size = @vfile_write_obj.size
      (0..9).each do
        @vfile_write_obj << write_str
        size = @vfile_write_obj.size
        expect(size).to eq(last_size + write_str.bytesize)
        last_size = size
      end
    end

    it "should write data that's readable" do
      write_str = "0123456789"
      (0..9).each do
        @vfile_write_obj << write_str
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

    it "should accept non-string objects as input" do
      write_obj = 123456789
      test_str = write_obj.to_s

      @vfile_write_obj << write_obj

      @vfile_write_obj.close
      @vfile_write_obj = VirtFS::VFile.new(@write_file_path, "r")

      expect(@vfile_write_obj.sysread(test_str.bytesize)).to eq(test_str)
    end

    it "should append to an existing file" do
      write_str      = ":NEW END OF FILE"
      new_end_marker = @end_marker + write_str

      vfile_test_obj = VirtFS::VFile.new(@full_path, "a")
      vfile_test_obj << write_str
      vfile_test_obj.close

      fobj = VfsRealFile.new(@full_path, "r")
      fobj.seek(-new_end_marker.bytesize, IO::SEEK_END)
      expect(fobj.sysread(new_end_marker.bytesize)).to eq(new_end_marker)
      fobj.close
    end

    it "should support read/write" do
      new_text = "ADDED TEXT\n"

      vfile_test_obj = VirtFS::VFile.new(@full_path, "r+")
      vfile_test_obj.pos = 0
      rv = vfile_test_obj.read(@start_marker.bytesize)
      expect(rv).to eq(@start_marker)

      test_text = rv + new_text

      vfile_test_obj << new_text
      vfile_test_obj.pos = 0
      expect(vfile_test_obj.read(test_text.bytesize)).to eq(test_text)
      vfile_test_obj.close

      fobj = VfsRealFile.new(@full_path, "r")
      expect(fobj.sysread(test_text.bytesize)).to eq(test_text)
      fobj.close
    end
  end

  describe "#eof, #eof?" do
    it "should return false when the file is not at EOF" do
      expect(@vfile_read_obj.eof).to be false
    end

    it "should return true when the file is at EOF" do
      @vfile_read_obj.seek(0, IO::SEEK_END)
      expect(@vfile_read_obj.eof).to be true
    end

    it "should raise IOError when the file isn't open for reading" do
      expect do
        @vfile_write_obj.eof
      end.to raise_error(
        IOError, /not opened for reading/
      )
    end
  end

  describe "#external_encoding" do
    it "should return the default external encoding, when not changed" do
      expect(@vfile_read_obj.external_encoding).to eq(Encoding.default_external)
    end
  end

  describe "#fdatasync" do
    it "should return 0" do
      expect(@vfile_write_obj.fdatasync).to eq(0)
    end
  end

  describe "#flush" do
    it "should return the IO object" do
      expect(@vfile_write_obj.flush).to eq(@vfile_write_obj)
    end
  end

  describe "#fsync" do
    it "should return 0" do
      expect(@vfile_write_obj.fsync).to eq(0)
    end
  end

  describe "#internal_encoding" do
    it "should return the default internal encoding, when not changed" do
      expect(@vfile_read_obj.internal_encoding).to eq(Encoding.default_internal)
    end
  end

  describe "#lineno" do
    it "should return 0 for newly opened file" do
      expect(@vfile_read_obj.lineno).to eq(0)
    end

    it "should raise IOError when the file isn't open for reading" do
      expect do
        @vfile_write_obj.lineno
      end.to raise_error(
        IOError, /not opened for reading/
      )
    end

    it "should increment with each line read" do
      expected_lineno = 1
      while @vfile_read_obj.gets
        expect(@vfile_read_obj.lineno).to eq(expected_lineno)
        expected_lineno += 1
      end
    end
  end

  describe "#lineno=" do
    it "should return the new value" do
      new_val = 128
      expect(@vfile_read_obj.lineno = new_val).to eq(new_val)
    end

    it "should raise IOError when the file isn't open for reading" do
      expect do
        @vfile_write_obj.lineno = 10
      end.to raise_error(
        IOError, /not opened for reading/
      )
    end

    it "should set the lineno" do
      set_lineno = 100
      @vfile_read_obj.lineno = set_lineno
      expected_lineno = set_lineno + 1
      while @vfile_read_obj.gets
        expect(@vfile_read_obj.lineno).to eq(expected_lineno)
        expected_lineno += 1
      end
    end
  end

  describe "#pos" do
    it "should return 0 for a newly opened file" do
      expect(@vfile_read_obj.pos).to eq(0)
    end

    it "should return the new position after a seek" do
      offset = @file_size / 2
      @vfile_read_obj.seek(offset)
      expect(@vfile_read_obj.pos).to eq(offset)
    end

    it "should return the new position after a read" do
      rv = @vfile_read_obj.sysread(@data1.bytesize)
      expect(rv.bytesize).to eq(@data1.bytesize)
      expect(@vfile_read_obj.pos).to eq(@data1.bytesize)
    end
  end

  describe "#pos=" do
    it "should return the new position" do
      expect(@vfile_read_obj.pos = 10).to eq(10)
    end

    it "should raise Errno::EINVAL when position is negative" do
      expect do
        @vfile_read_obj.pos = -10
      end.to raise_error(
        Errno::EINVAL, /Invalid argument/
      )
    end

    it "should change the read position within the file" do
      @vfile_read_obj.pos = @start_marker.bytesize
      rv = @vfile_read_obj.sysread(@data1.bytesize) # change to #read
      expect(rv).to eq(@data1)
    end
  end

  describe "#print" do
    it "should return nil" do
      expect(@vfile_write_obj.print("hello")).to be_nil
    end

    it "should write data that's readable" do
      write_str = "0123456789"
      (0..9).each do
        @vfile_write_obj.print write_str
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

    it "should accept non-string objects as input" do
      write_obj = 123456789
      test_str = write_obj.to_s

      @vfile_write_obj.print write_obj

      @vfile_write_obj.close
      @vfile_write_obj = VirtFS::VFile.new(@write_file_path, "r")

      expect(@vfile_write_obj.sysread(test_str.bytesize)).to eq(test_str)
    end

    it "should concatenate string arguments" do
      print_args = %w( one, two, three, four )
      test_str = print_args.join

      @vfile_write_obj.print(*print_args)

      @vfile_write_obj.close
      @vfile_write_obj = VirtFS::VFile.new(@write_file_path, "r")

      expect(@vfile_write_obj.sysread(test_str.bytesize)).to eq(test_str)
    end

    it "should concatenate non-string arguments" do
      print_args = [1, 2, 3, 4]
      test_str = "1234"

      @vfile_write_obj.print(*print_args)

      @vfile_write_obj.close
      @vfile_write_obj = VirtFS::VFile.new(@write_file_path, "r")

      expect(@vfile_write_obj.sysread(test_str.bytesize)).to eq(test_str)
    end

    # it "should print $_ by default" do
    #   test_str = "default string"
    # 
    #   $_ = test_str
    #   @vfile_write_obj.print
    # 
    #   @vfile_write_obj.close
    #   @vfile_write_obj = VirtFS::VFile.new(@write_file_path, "r")
    # 
    #   expect(@vfile_write_obj.sysread(test_str.bytesize)).to eq(test_str)
    # end

    it "should append $\ to the output - if it's set" do
      write_str = "Hello World"
      ors       = ":END"
      test_str  = write_str + ors

      $\ = ors
      @vfile_write_obj.print write_str
      $\ = nil

      @vfile_write_obj.close
      @vfile_write_obj = VirtFS::VFile.new(@write_file_path, "r")

      expect(@vfile_write_obj.sysread(test_str.bytesize)).to eq(test_str)
    end

    it "should insert $, between fields - if it's set" do
      print_args = [1, 2, 3, 4]
      ofs        = ", "
      test_str   = "1, 2, 3, 4"

      $, = ofs
      @vfile_write_obj.print(*print_args)
      $, = nil

      @vfile_write_obj.close
      @vfile_write_obj = VirtFS::VFile.new(@write_file_path, "r")

      expect(@vfile_write_obj.sysread(test_str.bytesize)).to eq(test_str)
    end
  end

  describe "#printf" do
    it "should return nil" do
      expect(@vfile_write_obj.printf("hello")).to be_nil
    end

    it "should output a formatted string" do
      fmt      = "%s %s: %d"
      args     = ["Hello", "World", 123]
      test_str = format(fmt, *args)

      @vfile_write_obj.printf(fmt, *args)

      @vfile_write_obj.close
      @vfile_write_obj = VirtFS::VFile.new(@write_file_path, "r")

      expect(@vfile_write_obj.sysread(test_str.bytesize)).to eq(test_str)
    end

    it "should output a formatted string - given hash args" do
      fmt      = "%{word1} %{word2}: %{num}"
      args     = {:word1 => "Hello", :num => 123, :word2 => "World"}
      test_str = format(fmt, args)

      @vfile_write_obj.printf(fmt, args)

      @vfile_write_obj.close
      @vfile_write_obj = VirtFS::VFile.new(@write_file_path, "r")

      expect(@vfile_write_obj.sysread(test_str.bytesize)).to eq(test_str)
    end
  end

  describe "#putc" do
    it "should return its arg" do
      arg = "hello"
      expect(@vfile_write_obj.putc arg).to eq(arg)
    end

    it "should output the first character of a string" do
      write_obj = "hello"
      test_str = write_obj[0]

      @vfile_write_obj.putc write_obj

      @vfile_write_obj.close
      @vfile_write_obj = VirtFS::VFile.new(@write_file_path, "r")

      expect(@vfile_write_obj.sysread(test_str.bytesize)).to eq(test_str)
    end

    it "should output the character representation of an integer" do
      write_obj = 65
      test_str = write_obj.chr

      @vfile_write_obj.putc write_obj

      @vfile_write_obj.close
      @vfile_write_obj = VirtFS::VFile.new(@write_file_path, "r")

      expect(@vfile_write_obj.sysread(test_str.bytesize)).to eq(test_str)
    end
  end

  describe "#puts" do
    it "should return nil" do
      expect(@vfile_write_obj.puts "hello").to be_nil
    end

    it "should output a single new line - when called without args" do
      @vfile_write_obj.puts

      @vfile_write_obj.close
      @vfile_write_obj = VirtFS::VFile.new(@write_file_path, "r")

      expect(@vfile_write_obj.sysread($/.bytesize)).to eq($/)
    end

    it "should write each arg on a new line" do
      args     = %w(line1 line2 line3)
      test_str = args.join($/) + $/

      @vfile_write_obj.puts(*args)

      @vfile_write_obj.close
      @vfile_write_obj = VirtFS::VFile.new(@write_file_path, "r")

      expect(@vfile_write_obj.sysread(test_str.bytesize)).to eq(test_str)
    end

    it "should not duplicate separators" do
      args     = %W(line1#{$/} line2#{$/} line3#{$/})
      test_str = "line1#{$/}line2#{$/}line3#{$/}"

      @vfile_write_obj.puts(*args)

      @vfile_write_obj.close
      @vfile_write_obj = VirtFS::VFile.new(@write_file_path, "r")

      expect(@vfile_write_obj.sysread(test_str.bytesize)).to eq(test_str)
    end
  end

  describe "#readbyte" do
    it "should return a Fixnum" do
      expect(@vfile_read_obj.getbyte).to be_kind_of(Fixnum)
    end

    it "should raise EOFError when at EOF" do
      @vfile_read_obj.read
      expect { @vfile_read_obj.readbyte }.to raise_error(EOFError, "end of file reached")
    end
  end

  describe "#readchar" do
    it "should return a character of the expected encoding" do
      expect(@vfile_read_obj.readchar.encoding).to eq(@vfile_read_obj.external_encoding)
    end

    it "should raise EOFError when at EOF" do
      @vfile_read_obj.read
      expect { @vfile_read_obj.readchar }.to raise_error(EOFError, "end of file reached")
    end
  end

  describe "#readline" do
    it "should read an entire line by default" do
      rv = @vfile_read_obj.readline
      expect(rv[-1]).to eq($/.encode(rv.encoding))
    end

    it "should raise EOFError when at EOF" do
      @vfile_read_obj.read
      expect { @vfile_read_obj.readline }.to raise_error(EOFError, "end of file reached")
    end
  end

  describe "#readpartial" do
    it "should do something"
  end

  describe "#rewind" do
    it "should return 0" do
      expect(@vfile_read_obj.rewind).to eq(0)
    end

    it "should reposition IO position to the start of file" do
      rv = @vfile_read_obj.sysread(@start_marker.bytesize)
      expect(rv).to eq(@start_marker)
      rv = @vfile_read_obj.sysread(@start_marker.bytesize)
      expect(rv).to_not eq(@start_marker)

      @vfile_read_obj.rewind

      rv = @vfile_read_obj.sysread(@start_marker.bytesize)
      expect(rv).to eq(@start_marker)
    end
  end

  describe "#seek" do
    it "should raise Errno::EINVAL when attempting to seek before the beginning of the file" do
      expect do
        @vfile_read_obj.sysseek(-10, IO::SEEK_CUR)
      end.to raise_error(
        Errno::EINVAL, /Invalid argument/
      )
    end

    it "should return 0" do
      offset = @file_size / 2
      rv = @vfile_read_obj.seek(offset, IO::SEEK_SET)
      expect(rv).to eq(0)
    end

    it "should change the read position within the file - IO::SEEK_SET" do
      @vfile_read_obj.seek(@start_marker.bytesize, IO::SEEK_SET)
      rv = @vfile_read_obj.sysread(@data1.bytesize) # change to #read
      expect(rv).to eq(@data1)
    end

    it "should change the read position within the file - IO::SEEK_CUR" do
      @vfile_read_obj.seek(@start_marker.bytesize, IO::SEEK_SET)
      @vfile_read_obj.seek(@data1.bytesize, IO::SEEK_CUR)
      rv = @vfile_read_obj.sysread(@data2.bytesize) # change to #read
      expect(rv).to eq(@data2)
    end

    it "should change the read position within the file - IO::SEEK_END" do
      @vfile_read_obj.seek(-@end_marker.bytesize, IO::SEEK_END)
      rv = @vfile_read_obj.sysread(@end_marker.bytesize) # change to #read
      expect(rv).to eq(@end_marker)
    end
  end

  describe "#set_encoding" do
    before(:each) do
      @target_external_str = "UTF-16LE"
      @target_internal_str = "US-ASCII"
      @target_external_obj = Encoding.find(@target_external_str)
      @target_internal_obj = Encoding.find(@target_internal_str)

      @vfile_read_test_obj  = VirtFS::VFile.new(@full_path, "rb")
    end

    after(:each) do
      @vfile_read_test_obj.close
    end

    it "should return the IO object" do
      expect(@vfile_read_test_obj.set_encoding(@target_external_str)).to eq(@vfile_read_test_obj)
    end

    it "should raise ArgumentError when passed 0 args" do
      expect do
        @vfile_read_test_obj.set_encoding
      end.to raise_error(
        ArgumentError, "wrong number of arguments (0 for 1..2)"
      )
    end

    it "should raise ArgumentError when passed more than 2 args" do
      expect do
        @vfile_read_test_obj.set_encoding("x", "Y", "Z")
      end.to raise_error(
        ArgumentError, "wrong number of arguments (3 for 1..2)"
      )
    end

    it "should raise TypeError when passed unexpected types - first arg" do
      expect do
        @vfile_read_test_obj.set_encoding(100)
      end.to raise_error(
        TypeError, /no implicit conversion of/
      )
    end

    it "should raise TypeError when passed unexpected types - second arg" do
      expect do
        @vfile_read_test_obj.set_encoding(@target_external_str, 100)
      end.to raise_error(
        TypeError, /no implicit conversion of/
      )
    end

    context "given encoding objects" do
      it "should change external and internal encodings" do
        expect(@vfile_read_test_obj.external_encoding).to_not eq(@target_external_obj)
        expect(@vfile_read_test_obj.internal_encoding).to_not eq(@target_internal_obj)

        @vfile_read_test_obj.set_encoding(@target_external_obj, @target_internal_obj)

        expect(@vfile_read_test_obj.external_encoding).to eq(@target_external_obj)
        expect(@vfile_read_test_obj.internal_encoding).to eq(@target_internal_obj)
      end

      # XXX - Real IO objects don't seem to behave like this.
      # it "should default internal to external - when internal omitted" do
      #   expect(@vfile_read_test_obj.external_encoding).to_not eq(@target_external_obj)
      #   expect(@vfile_read_test_obj.internal_encoding).to_not eq(@target_external_obj)
      #
      #   @vfile_read_test_obj.set_encoding(@target_external_obj)
      #
      #   expect(@vfile_read_test_obj.external_encoding).to eq(@target_external_obj)
      #   expect(@vfile_read_test_obj.internal_encoding).to eq(@target_external_obj)
      # end
    end

    context "given strings" do
      it "should change external and internal encodings" do
        expect(@vfile_read_test_obj.external_encoding).to_not eq(@target_external_obj)
        expect(@vfile_read_test_obj.internal_encoding).to_not eq(@target_internal_obj)

        @vfile_read_test_obj.set_encoding(@target_external_str, @target_internal_str)

        expect(@vfile_read_test_obj.external_encoding).to eq(@target_external_obj)
        expect(@vfile_read_test_obj.internal_encoding).to eq(@target_internal_obj)
      end

      # XXX - No, it shouldn't.
      # it "should default internal to external - when internal omitted" do
      #   expect(@vfile_read_test_obj.external_encoding).to_not eq(@target_external_obj)
      #   expect(@vfile_read_test_obj.internal_encoding).to_not eq(@target_external_obj)
      #
      #   @vfile_read_test_obj.binmode
      #   @vfile_read_test_obj.set_encoding(@target_external_str)
      #
      #   expect(@vfile_read_test_obj.external_encoding).to eq(@target_external_obj)
      #   expect(@vfile_read_test_obj.internal_encoding).to eq(@target_external_obj)
      # end
    end

    context "given mixed types" do
      it "should work with (Encoding, String)" do
        expect(@vfile_read_test_obj.external_encoding).to_not eq(@target_external_obj)
        expect(@vfile_read_test_obj.internal_encoding).to_not eq(@target_internal_obj)

        @vfile_read_test_obj.set_encoding(@target_external_obj, @target_internal_str)

        expect(@vfile_read_test_obj.external_encoding).to eq(@target_external_obj)
        expect(@vfile_read_test_obj.internal_encoding).to eq(@target_internal_obj)
      end

      it "should work with (String, Encoding)" do
        expect(@vfile_read_test_obj.external_encoding).to_not eq(@target_external_obj)
        expect(@vfile_read_test_obj.internal_encoding).to_not eq(@target_internal_obj)

        @vfile_read_test_obj.set_encoding(@target_external_str, @target_internal_obj)

        expect(@vfile_read_test_obj.external_encoding).to eq(@target_external_obj)
        expect(@vfile_read_test_obj.internal_encoding).to eq(@target_internal_obj)
      end
    end
  end

  describe "#sync" do
    it "should return false by default" do
      expect(@vfile_write_obj.sync).to be false
    end
  end

  describe "#sync=" do
    it "should return the new sync mode" do
      expect(@vfile_write_obj.sync).to be false
      expect(@vfile_write_obj.sync = true).to be true
    end

    it "should change the sync mode" do
      expect(@vfile_write_obj.sync).to be false
      expect(@vfile_write_obj.sync = true).to be true
      expect(@vfile_write_obj.sync).to be true
    end
  end

  describe "#write" do
    it "should return the number of bytes written" do
      write_str = "0123456789"
      expect(@vfile_write_obj.write(write_str)).to eq(write_str.bytesize)
    end

    it "should update the current file position" do
      write_str = "0123456789"
      last_pos = @vfile_write_obj.pos
      (0..9).each do
        @vfile_write_obj.write(write_str)
        pos = @vfile_write_obj.pos
        expect(pos).to eq(last_pos + write_str.bytesize)
        last_pos = pos
      end
    end

    it "should update the size of the file" do
      write_str = "0123456789"
      last_size = @vfile_write_obj.size
      (0..9).each do
        @vfile_write_obj.write(write_str)
        size = @vfile_write_obj.size
        expect(size).to eq(last_size + write_str.bytesize)
        last_size = size
      end
    end

    it "should write data that's readable" do
      write_str = "0123456789"
      (0..9).each do
        @vfile_write_obj.write(write_str)
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

    it "should append to an existing file" do
      write_str      = ":NEW END OF FILE"
      new_end_marker = @end_marker + write_str

      vfile_test_obj = VirtFS::VFile.new(@full_path, "a")
      vfile_test_obj.write(write_str)
      vfile_test_obj.close

      fobj = VfsRealFile.new(@full_path, "r")
      fobj.seek(-new_end_marker.bytesize, IO::SEEK_END)
      expect(fobj.sysread(new_end_marker.bytesize)).to eq(new_end_marker)
      fobj.close
    end

    it "should support read/write" do
      new_text = "ADDED TEXT\n"

      vfile_test_obj = VirtFS::VFile.new(@full_path, "r+")
      vfile_test_obj.pos = 0
      rv = vfile_test_obj.read(@start_marker.bytesize)
      expect(rv).to eq(@start_marker)

      test_text = rv + new_text

      vfile_test_obj.write(new_text)
      vfile_test_obj.pos = 0
      expect(vfile_test_obj.read(test_text.bytesize)).to eq(test_text)
      vfile_test_obj.close

      fobj = VfsRealFile.new(@full_path, "r")
      expect(fobj.sysread(test_text.bytesize)).to eq(test_text)
      fobj.close
    end
  end

  describe "#write_nonblock" do
    it "should do something"
  end
end
