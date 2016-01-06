require 'spec_helper'

describe VirtFS::Context do
  before(:all) do
    @full_path = File.expand_path(__FILE__)
    @rel_path  = File.basename(@full_path)
    @this_dir  = File.dirname(@full_path)
    @root      = File::SEPARATOR

    @new_root      = VfsRealFile.expand_path(VfsRealFile.join(__dir__, ".."))
    @new_this_dir  = VfsRealFile.expand_path(VfsRealFile.join("/", VfsRealFile.basename(__dir__)))
    @new_full_path = VfsRealFile.expand_path(VfsRealFile.join(@new_this_dir, VfsRealFile.basename(__FILE__)))
  end

  before(:each) do
    reset_context
    @context0 = VirtFS::Context.new
  end

  describe "#mount" do
    before(:each) do
      @native_fs = nativefs_class.new
    end

    context "single filesystem:" do
      it "should raise RuntimeError when an invalid filesystem is provided" do
        expect do
          @context0.mount(nil, @root)
        end.to raise_error(
          RuntimeError, "mount: invalid filesystem object #{nil.class.name}"
        )
      end

      it "should raise Errno::ENOENT when mount point doesn't exist" do
        expect do
          @context0.mount(@native_fs, @this_dir)
        end.to raise_error(
          Errno::ENOENT, "No such file or directory - #{@this_dir}"
        )
      end

      it "should raise RuntimeError when attempting to reuse mount point" do
        expect do
          @context0.mount(@native_fs, @root)
          @context0.mount(nativefs_class.new, @root)
        end.to raise_error(
          RuntimeError, "mount: mount point #{@root} is busy"
        )
      end

      it "should raise RuntimeError when attempting to mount a mounted filesystem" do
        expect do
          @context0.mount(@native_fs, @root)
          @context0.mount(@native_fs, @this_dir)
        end.to raise_error(
          RuntimeError, "mount: filesystem is busy"
        )
      end

      it "should return nil on successful mount" do
        expect(@context0.mount(@native_fs, @root)).to be_nil
      end
    end

    context "second filesystem:" do
      before(:each) do
        @native_fs2 = nativefs_class.new
        @context0.mount(@native_fs, @root)
      end

      it "should raise RuntimeError when attempting to reuse mount point" do
        expect do
          @context0.mount(@native_fs2, @this_dir)
          @context0.mount(nativefs_class.new, @this_dir)
        end.to raise_error(
          RuntimeError, "mount: mount point #{@this_dir} is busy"
        )
      end

      it "should return nil on successful mount" do
        expect(@context0.mount(@native_fs2, @this_dir)).to be_nil
      end
    end
  end

  describe "#umount" do
    before(:each) do
      @native_fs = nativefs_class.new
    end

    it "should raise RuntimeError when nothing mounted on mount point" do
      @context0.mount(@native_fs, @root)
      expect do
        @context0.umount(@this_dir)
      end.to raise_error(
        RuntimeError, "umount: nothing mounted on #{@this_dir}"
      )
    end

    it "should return nil on successful umount" do
      @context0.mount(@native_fs, @root)
      expect(@context0.umount(@root)).to be_nil
    end

    it "should enable re-mount" do
      @context0.mount(@native_fs, @root)
      @context0.umount(@root)
      expect(@context0.mount(@native_fs, @root)).to be_nil
    end
  end

  describe "#mount_points" do
    it "should return an Array" do
      expect(@context0.mount_points).to be_kind_of(Array)
    end

    it "should return an empty Array when nothing mounted" do
      expect(@context0.mount_points.empty?).to be true
    end

    it "should return an array of the expected length" do
      expect(@context0.mount_points.length).to eq(0)
      native_fs1 = nativefs_class.new
      @context0.mount(native_fs1, @root)
      expect(@context0.mount_points.length).to eq(1)
      native_fs2 = nativefs_class.new
      @context0.mount(native_fs2, @this_dir)
      expect(@context0.mount_points.length).to eq(2)
    end

    it "should return an array containing expected values" do
      expect(@context0.mount_points).to match_array([])
      native_fs1 = nativefs_class.new
      @context0.mount(native_fs1, @root)
      expect(@context0.mount_points).to match_array([@root])
      native_fs2 = nativefs_class.new
      @context0.mount(native_fs2, @this_dir)
      expect(@context0.mount_points).to match_array([@root, @this_dir])
    end
  end

  describe "#mounted?" do
    it "should return false when nothing is mounted" do
      expect(@context0.mounted?(@root)).to be false
    end

    it "should return false, given a directory that's not a mount point" do
      native_fs1 = nativefs_class.new
      @context0.mount(native_fs1, @root)
      expect(@context0.mounted?(@this_dir)).to be false
    end

    it "should return true, given a directory that is a mount point" do
      native_fs1 = nativefs_class.new
      @context0.mount(native_fs1, @root)
      expect(@context0.mounted?(@root)).to be true
      native_fs2 = nativefs_class.new
      @context0.mount(native_fs2, @this_dir)
      expect(@context0.mounted?(@this_dir)).to be true
    end
  end

  describe "#fs_on" do
    it "should return nil when nothing is mounted" do
      expect(@context0.fs_on(@root)).to be nil
    end

    it "should return nil, given a directory that's not a mount point" do
      native_fs1 = nativefs_class.new
      @context0.mount(native_fs1, @root)
      expect(@context0.fs_on(@this_dir)).to be nil
    end

    it "should return the FS object for the filesystem mounted on the mount point" do
      native_fs1 = nativefs_class.new
      @context0.mount(native_fs1, @root)
      expect(@context0.fs_on(@root)).to eq(native_fs1)
      native_fs2 = nativefs_class.new
      @context0.mount(native_fs2, @this_dir)
      expect(@context0.fs_on(@this_dir)).to eq(native_fs2)
    end
  end

  describe "#chroot" do
    before(:each) do
      @native_fs = nativefs_class.new
      @context0.mount(@native_fs, @root)
    end

    it "should raise Errno::ENOENT when directory does exist" do
      expect do
        @context0.chroot("/not_a_dir/foo.d")
      end.to raise_error(
        Errno::ENOENT, /No such file or directory/
      )
    end

    it "should return 0 on success" do
      expect(@context0.chroot(@this_dir)).to eq(0)
    end

    it "should set the value of root accordingly" do
      @context0.chroot(@new_root)
      _cwd, root = @context0.cwd_root
      expect(root).to eq(@new_root)
    end

    it "should set the current directory to '/'" do
      @context0.chroot(@new_root)
      cwd, _root = @context0.cwd_root
      expect(cwd).to eq(File::SEPARATOR)
    end

    it "should find directory through new full path" do
      @context0.chroot(@new_root)
      expect(@context0.dir_exist?(@new_this_dir)).to be true
    end
  end

  describe "#with_root" do
    before(:each) do
      @native_fs = nativefs_class.new
      @context0.mount(@native_fs, @root)
    end

    it "should raise Errno::ENOENT when directory does exist" do
      expect do
        @context0.with_root("/not_a_dir/foo.d") {}
      end.to raise_error(
        Errno::ENOENT, /No such file or directory/
      )
    end

    it "should raise LocalJumpError when no block given" do
      expect do
        @context0.with_root(@this_dir)
      end.to raise_error(
        LocalJumpError, /no block given/
      )
    end

    it "should set the value of root within the block" do
      _cwd, root0 = @context0.cwd_root
      expect(root0).to_not eq(@new_root)

      @context0.with_root(@new_root) do
        _cwd, root1 = @context0.cwd_root
        expect(root1).to eq(@new_root)
      end
      
      _cwd, root2 = @context0.cwd_root
      expect(root2).to eq(root0)
    end
  end

  describe "#path_lookup" do
    context "with no filesystems mounted" do
      it "should raise Errno::ENOENT" do
        expect do
          @context0.path_lookup(@full_path)
        end.to raise_error(
          Errno::ENOENT, "No such file or directory - #{@full_path}"
        )
      end

      it "should raise Errno::ENOENT with original path in message" do
        expect do
          @context0.path_lookup(@rel_path)
        end.to raise_error(
          Errno::ENOENT, "No such file or directory - #{@rel_path}"
        )
      end
    end

    context "with FS mounted on #{@root}" do
      before(:each) do
        @native_fs = nativefs_class.new
        @context0.mount(@native_fs, @root)
      end

      it "should return native_fs, when given fully qualified path" do
        fs, _path = @context0.path_lookup(@full_path)
        expect(fs).to eq(@native_fs)
      end

      it "should return the full path, when given fully qualified path" do
        _fs, path = @context0.path_lookup(@full_path)
        expect(path).to eq(@full_path) # .sub(@native_fs.mount_point, '')
      end

      it "should return native_fs, when given relative path" do
        @context0.chdir(@this_dir)
        fs, _path = @context0.path_lookup(@rel_path)
        expect(fs).to eq(@native_fs)
      end

      it "should return the full path, when given relative path" do
        @context0.chdir(@this_dir)
        _fs, path = @context0.path_lookup(@rel_path)
        expect(path).to eq(@full_path) # .sub(@native_fs.mount_point, '')
      end
    end

    context "with FS mounted on #{@this_dir}" do
      before(:each) do
        @native_fs  = nativefs_class.new
        @native_fs2 = nativefs_class.new
        @context0.mount(@native_fs,  @root)
        @context0.mount(@native_fs2, @this_dir)
      end

      it "should return native_fs2, when given fully qualified path" do
        fs, _path = @context0.path_lookup(@full_path)
        expect(fs).to eq(@native_fs2)
      end

      it "should return the path relative to the mount point, when given fully qualified path" do
        _fs, path = @context0.path_lookup(@full_path)
        expect(path).to eq(@full_path.sub(@native_fs2.mount_point, File::SEPARATOR))
      end

      it "should return native_fs2, when given relative path" do
        @context0.chdir(@this_dir)
        fs, _path = @context0.path_lookup(@rel_path)
        expect(fs).to eq(@native_fs2)
      end

      it "should return the path relative to the mount point, when given relative path" do
        @context0.chdir(@this_dir)
        _fs, path = @context0.path_lookup(@rel_path)
        expect(path).to eq(@full_path.sub(@native_fs2.mount_point, File::SEPARATOR))
      end
    end
  end
end
