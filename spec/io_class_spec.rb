require 'spec_helper'

describe VirtFS::VIO, "(#{$fs_interface} interface)" do
  before(:all) do
    @temp_file    = Tempfile.new("VirtFS-IO")
    @temp_file.write(@start_marker)
    (0..9).each do
      @temp_file.write(@data1)
      @temp_file.write(@data2)
    end
    @temp_file.write(@end_marker)
    @temp_file.close

    @full_path = @temp_file.path

    @temp_write = Tempfile.new("VirtFS-IO")
    @temp_write.close
    @write_file_path = @temp_write.path
  end

  before(:each) do
    reset_context

    @root      = File::SEPARATOR
    @native_fs = nativefs_class.new
    VirtFS.mount(@native_fs, @root)

    @vfile_read_obj  = VirtFS::VFile.new(@full_path, "r")
    @vfile_write_obj = VirtFS::VFile.new(@write_file_path, "w")
  end

  after(:each) do
    VirtFS.umount(@root)
  end

  describe ".binread" do
    it "should return the same data as IO.binread - whole file" do
      expect(VirtFS::VIO.binread(@full_path)).to eq(VfsRealIO.binread(@full_path))
    end

    it "should return the same data as IO.binread - given length" do
      length = 30
      expect(VirtFS::VIO.binread(@full_path, length)).to eq(VfsRealIO.binread(@full_path, length))
    end

    it "should return the same data as IO.binread - given length and offset" do
      length = 30
      offset = 20
      expect(VirtFS::VIO.binread(@full_path, length, offset)).to eq(VfsRealIO.binread(@full_path, length, offset))
    end
  end

  describe ".copy_stream" do
    it "should return the number of bytes copied" do
      expect(VirtFS::VIO.copy_stream(@vfile_read_obj, @vfile_write_obj)).to eq(@vfile_read_obj.size)
    end

    it "should create a file of the same size" do
      VirtFS::VIO.copy_stream(@vfile_read_obj, @vfile_write_obj)
      expect(@vfile_write_obj.size).to eq(@vfile_read_obj.size)
    end

    it "should create a file with the same contents" do
      VirtFS::VIO.copy_stream(@vfile_read_obj, @vfile_write_obj)
      @vfile_read_obj.rewind
      @vfile_write_obj.reopen(@write_file_path, "r")
      expect(@vfile_write_obj.read).to eq(@vfile_read_obj.read)
    end
  end

  describe ".foreach" do
    it "should return an enum when no block is given" do
      expect(VirtFS::VIO.foreach(@full_path)).to be_kind_of(Enumerator)
    end

    it "should return the nil object when block is given" do
      expect(VirtFS::VIO.foreach(@full_path) { true }).to be_nil
    end

    it "should enumerate the same lines as the standard IO.foreach" do
      expect(VirtFS::VIO.foreach(@full_path).to_a).to match_array(VfsRealIO.foreach(@full_path).to_a)
    end
  end

  describe ".new" do
    it "should do something"
  end

  describe ".open" do
    it "should do something"
  end

  describe ".pipe" do
    it "should do something"
  end

  describe ".popen" do
    it "should do something"
  end

  describe ".read" do
    it "should return the same data as IO.read - whole file" do
      expect(VirtFS::VIO.read(@full_path)).to eq(VfsRealIO.read(@full_path))
    end

    it "should return the same data as IO.read - given length" do
      length = 30
      expect(VirtFS::VIO.read(@full_path, length)).to eq(VfsRealIO.read(@full_path, length))
    end

    it "should return the same data as IO.read - given length and offset" do
      length = 30
      offset = 20
      expect(VirtFS::VIO.read(@full_path, length, offset)).to eq(VfsRealIO.read(@full_path, length, offset))
    end
  end

  describe ".readlines" do
    it "should return an Array" do
      expect(VirtFS::VIO.readlines(@full_path)).to be_kind_of(Array)
    end

    it "should return the same lines as the standard IO.readlines" do
      expect(VirtFS::VIO.readlines(@full_path)).to match_array(VfsRealIO.readlines(@full_path))
    end
  end

  describe ".select" do
    it "should do something"
  end

  describe ".sysopen" do
    it "should do something"
  end

  describe ".try_convert" do
    it "should return nil when not passed an IO object" do
      expect(VirtFS::VIO.try_convert("this is a string")).to be_nil
    end

    it "should return the IO object when passed an IO object" do
      expect(VirtFS::VIO.try_convert(@vfile_read_obj)).to eq(@vfile_read_obj)
    end
  end
end
