require 'spec_helper'

describe "VirtFS.dir_chroot (#{$fs_interface} interface)" do
  before(:all) do
    @full_path  = VfsRealFile.expand_path(__FILE__)
    @this_dir   = VfsRealFile.expand_path(__dir__)
    @root       = File::SEPARATOR

    @new_root      = VfsRealFile.expand_path(VfsRealFile.join(__dir__, ".."))
    @new_this_dir  = VfsRealFile.expand_path(VfsRealFile.join("/", VfsRealFile.basename(__dir__)))
    @new_full_path = VfsRealFile.expand_path(VfsRealFile.join(@new_this_dir, VfsRealFile.basename(__FILE__)))
  end

  before(:each) do
    reset_context
    @native_fs  = nativefs_class.new
    VirtFS.mount(@native_fs, @root)
  end

  describe "Dir.chroot" do
    it "should raise Errno::ENOENT when directory does exist" do
      expect do
        VirtFS::VDir.chroot("/not_a_dir/foo.d")
      end.to raise_error(
        Errno::ENOENT, /No such file or directory/
      )
    end

    it "should return 0 on success" do
      expect(VirtFS::VDir.chroot(@this_dir)).to eq(0)
    end

    it "should set the value of root accordingly" do
      VirtFS::VDir.chroot(@new_root)
      expect(VirtFS.root).to eq(@new_root)
    end

    it "should set the current directory to '/'" do
      VirtFS::VDir.chroot(@new_root)
      expect(VirtFS::VDir.getwd).to eq(File::SEPARATOR)
    end

    it "should find directory through new full path" do
      VirtFS::VDir.chroot(@new_root)
      expect(VirtFS::VDir.exist?(@new_this_dir)).to be true
    end

    it "should find file through new full path" do
      VirtFS::VDir.chroot(@new_root)
      expect(VirtFS::VFile.exist?(@new_full_path)).to be true
    end
  end

  describe "Dir.chdir" do
    before(:all) do
      @parent_dir         = @new_root
      @child_dir          = @this_dir
      @rel_child_dir_name = VfsRealFile.basename(@child_dir)
      @abs_child_dir_name = VfsRealFile.join("/", @rel_child_dir_name)
    end

    it "should raise Errno::ENOENT when directory does exist under current root" do
      VirtFS::VDir.chroot(@child_dir)
      expect do
        VirtFS::VDir.chdir(@parent_dir)
      end.to raise_error(
        Errno::ENOENT, /No such file or directory/
      )
    end

    it "should cd to absolute path based on new root" do
      VirtFS::VDir.chroot(@parent_dir)
      VirtFS::VDir.chdir(@abs_child_dir_name)
      expect(VirtFS::VDir.getwd).to eq(@abs_child_dir_name)
    end

    it "should cd to relative path based on new root" do
      VirtFS::VDir.chroot(@parent_dir)
      VirtFS::VDir.chdir(@rel_child_dir_name)
      expect(VirtFS::VDir.getwd).to eq(@abs_child_dir_name)
    end

    it "should not permit traversal above root" do
      VirtFS::VDir.chroot(@parent_dir)
      VirtFS::VDir.chdir("..")
      expect(VirtFS::VDir.getwd).to eq("/")
      VirtFS::VDir.chdir(VfsRealFile.join("..", ".."))
      expect(VirtFS::VDir.getwd).to eq("/")
      VirtFS::VDir.chdir(VfsRealFile.join("..", "..", ".."))
      expect(VirtFS::VDir.getwd).to eq("/")
    end

    it "should traverse up to root, then back down" do
      VirtFS::VDir.chroot(@parent_dir)
      VirtFS::VDir.chdir(VfsRealFile.join("..", "..", "..", @rel_child_dir_name))
      expect(VirtFS::VDir.getwd).to eq(@abs_child_dir_name)
    end
  end

  describe "Dir.glob" do
    it "should enumerate the same file names as the standard Dir.glob - simple glob" do
      VirtFS::VDir.chroot(@new_root)
      VfsRealDir.chdir(@new_root) do # for VfsRealDir.glob
        expect(VirtFS::VDir.glob("*")).to eq(VfsRealDir.glob("*"))
        expect(VirtFS::VDir.glob("*/*.rb")).to eq(VfsRealDir.glob("*/*.rb"))
      end
    end

    it "should enumerate the same file names as the standard Dir.glob - relative glob" do
      VirtFS::VDir.chroot(@new_root)
      VfsRealDir.chdir(@new_root) do # for VfsRealDir.glob
        # We're at root, so the ".." will keep us at root.
        v_results = VirtFS::VDir.glob("../**/*.rb").collect { |f| VfsRealFile.basename(f) }.sort
        # We're not at root in the real FS, so omitting the ".." should result in the same files.
        r_results = VfsRealDir.glob("**/*.rb").collect { |f| VfsRealFile.basename(f) }.sort
        expect(v_results).to eq(r_results)
      end
    end
  end
end
