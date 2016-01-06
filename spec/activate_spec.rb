require 'spec_helper'

describe VirtFS, " - activation (#{$fs_interface} interface)" do
  before(:each) do
    reset_context
    @root = File::SEPARATOR
    @native_fs = nativefs_class.new
    VirtFS.mount(@native_fs, @root)
  end

  after(:each) do
    VirtFS.deactivate! if VirtFS.activated?
    VirtFS.umount(@root) if VirtFS.mounted?(@root)
  end

  it "should save reference to standard Dir class" do
    expect(Object.const_defined?(:VfsRealDir)).to be true
    expect(VfsRealDir).to eq(Dir)
  end

  it "should save reference to standard File class" do
    expect(Object.const_defined?(:VfsRealFile)).to be true
    expect(VfsRealFile).to eq(File)
  end

  it "should save reference to standard IO class" do
    expect(Object.const_defined?(:VfsRealIO)).to be true
    expect(VfsRealIO).to eq(IO)
  end

  it "should define VirtFS class" do
    expect(Object.const_defined?(:VirtFS)).to be true
  end

  it "should define VirtFS::VDir class" do
    expect(VirtFS.const_defined?(:VDir)).to be true
  end

  it "should define VirtFS::VFile class" do
    expect(VirtFS.const_defined?(:File)).to be true
  end

  it "should define VirtFS::VIO class" do
    expect(VirtFS.const_defined?(:IO)).to be true
  end

  describe ".activate!" do
    it "should cause .activated? to return true" do
      expect(VirtFS.activated?).to be false
      VirtFS.activate!
      expect(VirtFS.activated?).to be true
    end

    it "should set standard Dir class to VirtFS::Dir" do
      expect(Dir).to eq(VfsRealDir)
      VirtFS.activate!
      expect(Dir).to eq(VirtFS::VDir)
    end

    it "should set standard File class to VirtFS::File" do
      expect(File).to eq(VfsRealFile)
      VirtFS.activate!
      expect(File).to eq(VirtFS::VFile)
    end

    it "should set standard IO class to VirtFS::IO" do
      expect(IO).to eq(VfsRealIO)
      VirtFS.activate!
      expect(IO).to eq(VirtFS::VIO)
    end
  end

  describe ".deactivate!" do
    before(:each) do
      VirtFS.activate!
    end

    after(:each) do
      VirtFS.deactivate! if VirtFS.activated?
    end

    it "should cause .activated? to return false" do
      expect(VirtFS.activated?).to be true
      VirtFS.deactivate!
      expect(VirtFS.activated?).to be false
    end

    it "should set standard Dir class to VfsRealDir" do
      expect(Dir).to eq(VirtFS::VDir)
      VirtFS.deactivate!
      expect(Dir).to eq(VfsRealDir)
    end

    it "should set standard File class to VfsRealFile" do
      expect(File).to eq(VirtFS::VFile)
      VirtFS.deactivate!
      expect(File).to eq(VfsRealFile)
    end

    it "should set standard IO class to VfsRealDir" do
      expect(IO).to eq(VirtFS::VIO)
      VirtFS.deactivate!
      expect(IO).to eq(VfsRealIO)
    end
  end

  describe ".with" do
    after(:each) do
      VirtFS.deactivate! if VirtFS.activated?
    end

    it "should only be activated within block - when not activated initially" do
      expect(VirtFS.activated?).to be false
      VirtFS.with { expect(VirtFS.activated?).to be true }
      expect(VirtFS.activated?).to be false
    end

    it "should remain activated - when activated initially" do
      VirtFS.activate!
      expect(VirtFS.activated?).to be true
      VirtFS.with { expect(VirtFS.activated?).to be true }
      expect(VirtFS.activated?).to be true
    end
  end

  describe ".without" do
    after(:each) do
      VirtFS.deactivate! if VirtFS.activated?
    end

    it "should only be deactivated within block - when activated initially" do
      VirtFS.activate!
      expect(VirtFS.activated?).to be true
      VirtFS.without { expect(VirtFS.activated?).to be false }
      expect(VirtFS.activated?).to be true
    end

    it "should remain deactivated - when deactivated initially" do
      expect(VirtFS.activated?).to be false
      VirtFS.without { expect(VirtFS.activated?).to be false }
      expect(VirtFS.activated?).to be false
    end
  end

  describe "Dir objects" do
    it "should identify as standard Dir - when not activated" do
      Dir.open(__dir__) do |dir|
        expect(dir).to be_kind_of(Dir)
        expect(dir).to be_kind_of(VfsRealDir)
        expect(dir).not_to be_kind_of(VirtFS::VDir)
      end
    end

    it "should identify as VirtFS Dir - when activated" do
      VirtFS.with do
        Dir.open(__dir__) do |dir|
          expect(dir).to be_kind_of(Dir)
          expect(dir).to be_kind_of(VirtFS::VDir)
          expect(dir).not_to be_kind_of(VfsRealDir)
        end
      end
    end
  end

  describe "File objects" do
    it "should identify as standard File - when not activated" do
      File.open(__FILE__) do |file|
        expect(file).to be_kind_of(File)
        expect(file).to be_kind_of(VfsRealFile)
        expect(file).not_to be_kind_of(VirtFS::VFile)
      end
    end

    it "should identify as standard IO - when not activated" do
      File.open(__FILE__) do |file|
        expect(file).to be_kind_of(IO)
        expect(file).to be_kind_of(VfsRealIO)
        expect(file).not_to be_kind_of(VirtFS::VIO)
      end
    end

    it "should identify as VirtFS File - when activated" do
      VirtFS.with do
        File.open(__FILE__) do |file|
          expect(file).to be_kind_of(File)
          expect(file).to be_kind_of(VirtFS::VFile)
          expect(file).not_to be_kind_of(VfsRealFile)
        end
      end
    end

    it "should identify as VirtFS IO - when activated" do
      VirtFS.with do
        File.open(__FILE__) do |file|
          expect(file).to be_kind_of(IO)
          expect(file).to be_kind_of(VirtFS::VIO)
          expect(file).not_to be_kind_of(VfsRealIO)
        end
      end
    end
  end
end
