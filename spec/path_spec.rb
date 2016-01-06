require 'spec_helper'

describe VirtFS, "path support methods (#{$fs_interface} interface)" do
  before(:all) do
    @full_path = File.expand_path(__FILE__)
    @rel_path  = File.basename(@full_path)
    @this_dir  = File.dirname(@full_path)
  end

  before(:each) do
    reset_context
  end

  describe ".dir_getwd" do
    it "should default to '/'" do
      expect(VirtFS.dir_getwd).to eq('/')
    end

    it "return the value set by .dir_chdir" do
      VirtFS.cwd = @this_dir
      expect(VirtFS.dir_getwd).to eq(@this_dir)
    end
  end

  describe ".normalize_path" do
    it "should return full path, given full path" do
      expect(VirtFS.normalize_path(@full_path)).to eq(@full_path)
    end

    it "should return full path, given relative path" do
      expect(VirtFS.normalize_path(@rel_path, @this_dir)).to eq(@full_path)
    end

    it "should return full path, given relative path (based on cwd)" do
      VirtFS.cwd = @this_dir
      expect(VirtFS.normalize_path(@rel_path)).to eq(@full_path)
    end
  end
end
