require 'spec_helper' 

describe VirtFS::VFile, "(#{$fs_interface} interface)" do
  before(:all) do
    @spec_name   = VfsRealFile.basename(__FILE__, ".rb")
    @temp_prefix = "#{@spec_name}-"

    @ext        = ".rb"
    @data1      = "0123456789" * 4
    @temp_file  = Tempfile.new(["VirtFS-File", @ext])
    @temp_file.write(@data1)
    @temp_file.close
    @full_path  = @temp_file.path
    @rel_path   = File.basename(@full_path)
    @parent_dir = File.dirname(@full_path)

    @ext2        = ".c"
    @temp_file2  = Tempfile.new(["VirtFS-File", @ext2])
    @temp_file2.close
    @full_path2  = @temp_file2.path
    @rel_path2   = File.basename(@full_path2)
    @parent_dir2 = File.dirname(@full_path2)

    @slink_path  = temp_name(@temp_prefix, ".symlink")

    @root       = File::SEPARATOR
    @this_dir   = VfsRealDir.getwd
  end

  before(:each) do
    reset_context

    @native_fs = nativefs_class.new
    VirtFS.mount(@native_fs, @root)
  end

  describe "#atime" do
    it "should return the same value as the standard File#atime method" do
      VfsRealFile.open(@full_path) do |rf|
        VirtFS::VFile.open(@full_path) { |vf| expect(vf.atime).to eq(rf.atime) }
      end
    end
  end

  describe "#chmod" do
    it "should return 0" do
      VirtFS::VFile.open(@full_path) do |vf|
        expect(vf.chmod(0777)).to eq(0)
      end
    end

    it "should change the permission bits on the file" do
      target_mode = 0755
      expect(VfsRealFile.stat(@full_path).mode & 0777).to_not eq(target_mode)
      VirtFS::VFile.open(@full_path) do |vf|
        expect(vf.chmod(target_mode)).to be_zero
      end
      expect(VfsRealFile.stat(@full_path).mode & 0777).to eq(target_mode)
    end
  end

  describe "#chown" do
    it "should return 0 on success" do
      stat = VfsRealFile.stat(@full_path)

      VirtFS::VFile.open(@full_path) do |vf|
        expect(vf.chown(stat.uid, stat.gid)).to eq(0)
      end
    end
  end

  describe "#ctime" do
    it "should return the same value as the standard File#ctime method" do
      VfsRealFile.open(@full_path) do |rf|
        VirtFS::VFile.open(@full_path) { |vf| expect(vf.ctime).to eq(rf.ctime) }
      end
    end
  end

  describe "#flock" do
    it "should return 0" do
      VirtFS::VFile.open(@full_path) do |vf|
        expect(vf.flock(File::LOCK_EX)).to eq(0)
      end
    end
  end

  describe "#lstat" do
    before(:each) do
      VfsRealFile.symlink(@full_path, @slink_path)
    end

    after(:each) do
      VfsRealFile.delete(@slink_path)
    end

    it "should return the stat information for the symlink" do
      VirtFS::VFile.open(@slink_path) do |sl|
        expect(sl.lstat.symlink?).to be true
      end
    end
  end

  describe "#mtime" do
    it "should return the same value as the standard File#mtime method" do
      VfsRealFile.open(@full_path) do |rf|
        VirtFS::VFile.open(@full_path) { |vf| expect(vf.mtime).to eq(rf.mtime) }
      end
    end
  end

  describe "#path :to_path" do
    it "should return full path when opened with full path" do
      VirtFS::VFile.open(@full_path) { |f| expect(f.path).to eq(@full_path) }
    end

    it "should return relative path when opened with relative path" do
      parent, target_file = VfsRealFile.split(@full_path)
      VirtFS::VDir.chdir(parent)
      VirtFS::VFile.open(target_file) { |f| expect(f.path).to eq(target_file) }
    end
  end

  describe "#size" do
    it "should return the known size of the file" do
      VirtFS::VFile.open(@full_path) { |f| expect(f.size).to eq(@data1.bytesize) }
    end

    it "should return the same value as the standard File#size" do
      VfsRealFile.open(@full_path) do |rf|
        VirtFS::VFile.open(@full_path) { |vf| expect(vf.size).to eq(rf.size) }
      end
    end
  end

  describe "#truncate" do
    it "should return 0" do
      VirtFS::VFile.open(@full_path, "w") { |f| expect(f.truncate(5)).to eq(0) }
    end

    it "should raise IOError when file isn't open for writing" do
      VirtFS::VFile.open(@full_path, "r") do |f|
        expect { f.truncate(0) }.to raise_error(IOError, "not opened for writing")
      end
    end

    it "should truncate the file to the specified size" do
      tsize = @data1.bytesize / 2
      expect(VfsRealFile.size(@full_path)).to_not eq(tsize)
      VirtFS::VFile.open(@full_path, "w") { |f| f.truncate(tsize) }
      expect(VfsRealFile.size(@full_path)).to eq(tsize)
    end
  end
end
