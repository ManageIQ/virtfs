require 'spec_helper'

describe "NativeFS local root (mount subdurectory)" do
  before(:all) do
    @root           = VfsRealFile::SEPARATOR
    @mnt            = VfsRealDir.mktmpdir
    @top_dir        = "Dir1"

    @rb_file        = "hello_world.rb"
    @lib_name       = "hello_world"
    @module_name    = 'HelloWorld'

    @rb_code = <<-END_OF_CODE
      module #{@module_name}
        def self.hello
          "Hello World!"
        end
      end
    END_OF_CODE

    reset_context

    @native_fs1  = nativefs_class.new
    VirtFS.mount(@native_fs1, @root) # mount / on /
  end

  after(:all) do
    VirtFS.umount(@root) if VirtFS.mounted?(@root)
    VfsRealDir.rmdir(@mnt)
  end

  before(:each) do
    @tmp_dir = VfsRealDir.mktmpdir # The subdirectory to mount

    @native_fs2  = nativefs_class.new(@tmp_dir)
    VirtFS.mount(@native_fs2, @mnt)  # mount @tmp_dir on @mnt
  end

  after(:each) do
    VirtFS.umount(@mnt) if VirtFS.mounted?(@mnt)
    FileUtils.remove_dir(@tmp_dir)
  end

  context "Directory access -" do
    it "Directories created through the subdir should be visible through the mount point" do
      VirtFS::VDir.chdir(@tmp_dir) do
        mk_dir_tree(VirtFS::VDir, "Dir1", 4, 3)
        expect(check_dir_tree(VirtFS::VDir, "Dir1", 4, 3)).to be_nil
      end
      VirtFS::VDir.chdir(@mnt) do
        expect(check_dir_tree(VirtFS::VDir, "Dir1", 4, 3)).to be_nil
      end
    end

    it "Directories created through the mount point should be visible through the subdir" do
      VirtFS::VDir.chdir(@mnt) do
        mk_dir_tree(VirtFS::VDir, "Dir1", 4, 3)
        expect(check_dir_tree(VirtFS::VDir, "Dir1", 4, 3)).to be_nil
      end
      VirtFS::VDir.chdir(@tmp_dir) do
        expect(check_dir_tree(VirtFS::VDir, "Dir1", 4, 3)).to be_nil
      end
    end

    it "After unmount, directories should no longer be visible under mount point" do
      VirtFS::VDir.chdir(@mnt) do
        mk_dir_tree(VirtFS::VDir, "Dir1", 4, 3)
        expect(check_dir_tree(VirtFS::VDir, "Dir1", 4, 3)).to be_nil
      end

      VirtFS.umount(@mnt)

      VirtFS::VDir.chdir(@mnt) do
        expect do
          check_dir_tree(VirtFS::VDir, "Dir1", 4, 3)
        end.to raise_error(
          RuntimeError, "Expected directory Dir1 does not exist"
        )
      end
    end
  end

  context "File access -" do
    it "Files created through the subdir should be visible through the mount point" do
      VirtFS::VDir.chdir(@tmp_dir) do
        VirtFS::VFile.open(@rb_file, "w") do |f|
          f.write(@rb_code)
        end
        expect(VirtFS::VFile.exist?(@rb_file)).to be true
      end
      VirtFS::VDir.chdir(@mnt) do
        expect(VirtFS::VFile.exist?(@rb_file)).to be true
      end
    end

    it "Directories created through the mount point should be visible through the subdir" do
      VirtFS::VDir.chdir(@mnt) do
        VirtFS::VFile.open(@rb_file, "w") do |f|
          f.write(@rb_code)
        end
        expect(VirtFS::VFile.exist?(@rb_file)).to be true
      end
      VirtFS::VDir.chdir(@tmp_dir) do
        expect(VirtFS::VFile.exist?(@rb_file)).to be true
      end
    end

    it "After unmount, directories should no longer be visible under mount point" do
      VirtFS::VDir.chdir(@mnt) do
        VirtFS::VFile.open(@rb_file, "w") do |f|
          f.write(@rb_code)
        end
        expect(VirtFS::VFile.exist?(@rb_file)).to be true
      end

      VirtFS.umount(@mnt)

      VirtFS::VDir.chdir(@mnt) do
        expect(VirtFS::VFile.exist?(@rb_file)).to be false
      end
    end

    it "Reading file should return the expected data" do
      VirtFS::VDir.chdir(@mnt) do
        VirtFS::VFile.open(@rb_file, "w") do |f|
          f.write(@rb_code)
        end
        expect(VirtFS::VFile.read(@rb_file)).to eq(@rb_code)
      end
    end
  end
end
