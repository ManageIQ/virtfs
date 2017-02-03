require 'spec_helper'

describe "Load/Require operations through VirtFS -" do
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

    @dir_full_path  = VfsRealFile.join(@mnt, @top_dir)
    @file_full_path = VfsRealFile.join(@dir_full_path, @rb_file)

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

    @native_fs2 = nativefs_class.new(@tmp_dir)
    VirtFS.mount(@native_fs2, @mnt)  # mount @tmp_dir on @mnt

    VirtFS::VDir.mkdir(@dir_full_path)
    VirtFS::VFile.open(@file_full_path, "w") do |f|
      f.write(@rb_code)
    end
  end

  after(:each) do
    VirtFS.umount(@mnt) if VirtFS.mounted?(@mnt)
    FileUtils.remove_dir(@tmp_dir)
  end

  context "inject" do
    before(:each) do
      VirtFS::Kernel.withdraw
    end

    context "pre injection" do
      it "virtfs_original_require should be undefined" do
        expect(::Kernel.private_method_defined?(:virtfs_original_require)).to be false
      end

      it "virtfs_original_load should be undefined" do
        expect(::Kernel.private_method_defined?(:virtfs_original_load)).to be false
      end

      it "virtfs_require should be undefined" do
        expect(::Kernel.private_method_defined?(:virtfs_require)).to be false
      end

      it "virtfs_load should be undefined" do
        expect(::Kernel.private_method_defined?(:virtfs_load)).to be false
      end
    end

    context "post injection" do
      it "virtfs_original_require should be defined" do
        VirtFS::Kernel.inject
        expect(::Kernel.private_method_defined?(:virtfs_original_require)).to be true
      end

      it "virtfs_original_load should be defined" do
        VirtFS::Kernel.inject
        expect(::Kernel.private_method_defined?(:virtfs_original_load)).to be true
      end

      it "virtfs_require should be defined" do
        VirtFS::Kernel.inject
        expect(::Kernel.private_method_defined?(:virtfs_require)).to be true
      end

      it "virtfs_load should be defined" do
        VirtFS::Kernel.inject
        expect(::Kernel.private_method_defined?(:virtfs_load)).to be true
      end
    end
  end

  context "withdraw" do
    before(:each) do
      VirtFS::Kernel.inject
    end

    context "pre withdraw" do
      it "virtfs_original_require should be defined" do
        expect(::Kernel.private_method_defined?(:virtfs_original_require)).to be true
      end

      it "virtfs_original_load should be defined" do
        expect(::Kernel.private_method_defined?(:virtfs_original_load)).to be true
      end

      it "virtfs_require should be defined" do
        expect(::Kernel.private_method_defined?(:virtfs_require)).to be true
      end

      it "virtfs_load should be defined" do
        expect(::Kernel.private_method_defined?(:virtfs_load)).to be true
      end
    end

    context "post withdraw" do
      it "virtfs_original_require should be undefined" do
        VirtFS::Kernel.withdraw
        expect(::Kernel.private_method_defined?(:virtfs_original_require)).to be false
      end

      it "virtfs_original_load should be undefined" do
        VirtFS::Kernel.withdraw
        expect(::Kernel.private_method_defined?(:virtfs_original_load)).to be false
      end

      it "virtfs_require should be undefined" do
        VirtFS::Kernel.withdraw
        expect(::Kernel.private_method_defined?(:virtfs_require)).to be false
      end

      it "virtfs_load should be undefined" do
        VirtFS::Kernel.withdraw
        expect(::Kernel.private_method_defined?(:virtfs_load)).to be false
      end
    end
  end

  context "Check source file" do
    context "Not Activated" do
      it "Should exist under MetakitFS" do
        expect(VirtFS::VFile.exist?(@file_full_path)).to be true
      end

      it "Should not be visible outside of VirtFS" do
        expect(VfsRealFile.exist?(@file_full_path)).to be false
      end

      it "Should be of expected size" do
        expect(VirtFS::VFile.size(@file_full_path)).to eq(@rb_code.length)
      end

      it "Should contain expected code" do
        expect(VirtFS::VFile.read(@file_full_path)).to eq(@rb_code)
      end
    end

    context "Activated" do
      it "Should exist under MetakitFS" do
        VirtFS.with do
          expect(File.exist?(@file_full_path)).to be true
        end
      end

      it "Should be of expected size" do
        VirtFS.with do
          expect(File.size(@file_full_path)).to eq(@rb_code.length)
        end
      end

      it "Should contain expected code" do
        VirtFS.with do
          expect(File.read(@file_full_path)).to eq(@rb_code)
        end
      end
    end
  end

  context "load" do
    before(:each) do
      Object.send(:remove_const, @module_name) if Object.const_defined?(@module_name)
    end

    context "Activated" do
      it "Should return true on successful load" do
        VirtFS::Kernel.inject
        VirtFS.with do
          VirtFS::Kernel.enable # Add option to activate
          expect(load(@file_full_path)).to be true
          VirtFS::Kernel.disable
        end
      end

      it "Should load code as expected" do
        VirtFS::Kernel.inject
        VirtFS.with do
          VirtFS::Kernel.enable # Add option to activate
          expect(load(@file_full_path)).to be true
          VirtFS::Kernel.disable
          mod = Object.const_get(@module_name)
          expect(mod.hello).to eq("Hello World!")
        end
      end
    end

    context "Not Activated" do
      it "Should raise LoadError" do
        expect do
          load(@file_full_path)
        end.to raise_error(
          LoadError, /cannot load such file/
        )
      end
    end
  end

  context "require" do
    before(:each) do
      Object.send(:remove_const, @module_name) if Object.const_defined?(@module_name)
      $LOADED_FEATURES.delete(@file_full_path)
      $LOAD_PATH.delete(@dir_full_path)
    end

    context "Activated" do
      it "Should raise LoadError when not in $LOAD_PATH" do
        VirtFS.with(true) do
          expect do
            require(@lib_name)
          end.to raise_error(
            LoadError, /cannot load such file/
          )
        end
      end

      it "Should return true when loaded" do
        $LOAD_PATH << @dir_full_path
        VirtFS.with(true) do
          expect(require(@lib_name)).to be true
        end
      end

      it "Should return false when already loaded" do
        $LOAD_PATH << @dir_full_path
        VirtFS.with(true) do
          expect(require(@lib_name)).to be true
          expect(require(@lib_name)).to be false
        end
      end

      it "Should add the lib's canonical name to $LOADED_FEATURES" do
        $LOAD_PATH << @dir_full_path
        VirtFS.with(true) do
          expect(require(@lib_name)).to be true
          expect($LOADED_FEATURES.include?(@file_full_path))
        end
      end

      it "Should load the code as expected" do
        $LOAD_PATH << @dir_full_path
        VirtFS.with(true) do
          expect(require(@lib_name)).to be true
          expect(Object.const_defined?(@module_name)).to be true
          mod = Object.const_get(@module_name)
          expect(mod.hello).to eq("Hello World!")
        end
      end
    end

    context "Not Activated" do
      it "Should raise LoadError" do
        $LOAD_PATH << @dir_full_path
        expect do
          require(@lib_name)
        end.to raise_error(
          LoadError, /cannot load such file/
        )
      end
    end
  end
end
