require 'spec_helper'

describe VirtFS, "mount indirection (#{$fs_interface} interface) -" do
  before(:all) do
    @full_path = File.expand_path(__FILE__)
    @rel_path  = File.basename(@full_path)
    @this_dir  = File.dirname(@full_path)
    @root      = File::SEPARATOR
  end

  before(:each) do
    reset_context
  end

  describe ".mount" do
    before(:each) do
      @native_fs = nativefs_class.new
    end

    context "single filesystem:" do
      it "should raise RuntimeError when an invalid filesystem is provided" do
        expect do
          VirtFS.mount(nil, @root)
        end.to raise_error(
          RuntimeError, "mount: invalid filesystem object #{nil.class.name}"
        )
      end

      it "should raise Errno::ENOENT when mount point doesn't exist" do
        expect do
          VirtFS.mount(@native_fs, @this_dir)
        end.to raise_error(
          Errno::ENOENT, "No such file or directory - #{@this_dir}"
        )
      end

      it "should raise RuntimeError when attempting to reuse mount point" do
        expect do
          VirtFS.mount(@native_fs, @root)
          VirtFS.mount(nativefs_class.new, @root)
        end.to raise_error(
          RuntimeError, "mount: mount point #{@root} is busy"
        )
      end

      it "should raise RuntimeError when attempting to mount a mounted filesystem" do
        expect do
          VirtFS.mount(@native_fs, @root)
          VirtFS.mount(@native_fs, @this_dir)
        end.to raise_error(
          RuntimeError, "mount: filesystem is busy"
        )
      end

      it "should return nil on successful mount" do
        expect(VirtFS.mount(@native_fs, @root)).to be_nil
      end
    end

    context "second filesystem:" do
      before(:each) do
        @native_fs2 = nativefs_class.new
        VirtFS.mount(@native_fs, @root)
      end

      it "should raise RuntimeError when attempting to reuse mount point" do
        expect do
          VirtFS.mount(@native_fs2, @this_dir)
          VirtFS.mount(nativefs_class.new, @this_dir)
        end.to raise_error(
          RuntimeError, "mount: mount point #{@this_dir} is busy"
        )
      end

      it "should return nil on successful mount" do
        expect(VirtFS.mount(@native_fs2, @this_dir)).to be_nil
      end
    end
  end

  describe ".umount" do
    before(:each) do
      @native_fs = nativefs_class.new
    end

    it "should raise RuntimeError when nothing mounted on mount point" do
      VirtFS.mount(@native_fs, @root)
      expect do
        VirtFS.umount(@this_dir)
      end.to raise_error(
        RuntimeError, "umount: nothing mounted on #{@this_dir}"
      )
    end

    it "should return nil on successful umount" do
      VirtFS.mount(@native_fs, @root)
      expect(VirtFS.umount(@root)).to be_nil
    end

    it "should enable re-mount" do
      VirtFS.mount(@native_fs, @root)
      VirtFS.umount(@root)
      expect(VirtFS.mount(@native_fs, @root)).to be_nil
    end
  end

  describe ".path_lookup" do
    context "with no filesystems mounted" do
      it "should raise Errno::ENOENT" do
        expect do
          VirtFS.path_lookup(@full_path)
        end.to raise_error(
          Errno::ENOENT, "No such file or directory - #{@full_path}"
        )
      end

      it "should raise Errno::ENOENT with original path in message" do
        expect do
          VirtFS.path_lookup(@rel_path)
        end.to raise_error(
          Errno::ENOENT, "No such file or directory - #{@rel_path}"
        )
      end
    end

    context "with FS mounted on #{@root}" do
      before(:each) do
        @native_fs = nativefs_class.new
        VirtFS.mount(@native_fs, @root)
      end

      it "should return native_fs, when given fully qualified path" do
        fs, _path = VirtFS.path_lookup(@full_path)
        expect(fs).to eq(@native_fs)
      end

      it "should return the full path, when given fully qualified path" do
        _fs, path = VirtFS.path_lookup(@full_path)
        expect(path).to eq(@full_path) # .sub(@native_fs.mount_point, '')
      end

      it "should return native_fs, when given relative path" do
        VirtFS.dir_chdir(@this_dir)
        fs, _path = VirtFS.path_lookup(@rel_path)
        expect(fs).to eq(@native_fs)
      end

      it "should return the full path, when given relative path" do
        VirtFS.dir_chdir(@this_dir)
        _fs, path = VirtFS.path_lookup(@rel_path)
        expect(path).to eq(@full_path) # .sub(@native_fs.mount_point, '')
      end
    end

    context "with FS mounted on #{@this_dir}" do
      before(:each) do
        @native_fs  = nativefs_class.new
        @native_fs2 = nativefs_class.new
        VirtFS.mount(@native_fs,  @root)
        VirtFS.mount(@native_fs2, @this_dir)
      end

      it "should return native_fs2, when given fully qualified path" do
        fs, _path = VirtFS.path_lookup(@full_path)
        expect(fs).to eq(@native_fs2)
      end

      it "should return the path relative to the mount point, when given fully qualified path" do
        _fs, path = VirtFS.path_lookup(@full_path)
        expect(path).to eq(@full_path.sub(@native_fs2.mount_point, File::SEPARATOR))
      end

      it "should return native_fs2, when given relative path" do
        VirtFS.dir_chdir(@this_dir)
        fs, _path = VirtFS.path_lookup(@rel_path)
        expect(fs).to eq(@native_fs2)
      end

      it "should return the path relative to the mount point, when given relative path" do
        VirtFS.dir_chdir(@this_dir)
        _fs, path = VirtFS.path_lookup(@rel_path)
        expect(path).to eq(@full_path.sub(@native_fs2.mount_point, File::SEPARATOR))
      end
    end
  end
end
