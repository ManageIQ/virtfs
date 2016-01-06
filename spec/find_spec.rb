require 'spec_helper'

describe VirtFS, "find and support methods (#{$fs_interface} interface)" do
  before(:each) do
    reset_context
    @this_dir  = VfsRealDir.getwd
  end

  describe "::glob_depth" do
    it "should return the find depth required for the glob pattern" do
      expect(VirtFS.glob_depth("*")).to           eq(1)
      expect(VirtFS.glob_depth("*/*")).to         eq(2)
      expect(VirtFS.glob_depth("*/*/*.rb")).to    eq(3)
      expect(VirtFS.glob_depth("**")).to          eq(nil)
      expect(VirtFS.glob_depth("*.d/**/*.rb")).to eq(nil)
    end
  end

  describe "::find" do
    before(:each) do
      @full_path = File.expand_path(__FILE__)
      @rel_path  = File.basename(@full_path)
      @this_dir  = VfsRealDir.getwd
      @root      = File::SEPARATOR
    end

    context "with no filesystems mounted" do
      it "should raise Errno::ENOENT when given a nonexistent directory" do
        expect do
          VirtFS.find("nonexistent_directory")
        end.to raise_error(
          Errno::ENOENT, "No such file or directory - nonexistent_directory"
        )
      end

      it "should raise Errno::ENOENT when given a directory that exists in the native FS" do
        expect do
          VirtFS.find(@this_dir)
        end.to raise_error(
          Errno::ENOENT, "No such file or directory - #{@this_dir}"
        )
      end
    end

    context "with FS mounted on '/'" do
      before(:each) do
        @native_fs = nativefs_class.new
        VirtFS.mount(@native_fs, @root)
        VirtFS.dir_chdir(@this_dir)
      end

      it "should raise Errno::ENOENT when given a nonexistent directory" do
        expect do
          VirtFS.find("nonexistent_directory")
        end.to raise_error(
          Errno::ENOENT, "No such file or directory - nonexistent_directory"
        )
      end

      it "should return an enum when no block is given" do
        expect(VirtFS.find(@this_dir)).to be_kind_of(Enumerator)
      end

      it "should enumerate the same file names as standard Find.find" do
        require 'find'
        expect(VirtFS.find(@this_dir).to_a).to match_array(Find.find(@this_dir).to_a)
      end

      it "should retrieve paths that don't exceed the given depth - relative to the start directory" do
        require 'pathname'
        (0..4).each do |depth|
          VirtFS.find(@this_dir, depth) do |p|
            expect(Pathname.new(p.sub(@this_dir, "")).each_filename.to_a.length).to be <= depth
          end
        end
      end
    end
  end

  describe "::glob_str?" do
    it "should return false when string isn't a glob" do
      expect(VirtFS.glob_str?("hello")).to be false
    end

    it "should return true when string is a glob" do
      expect(VirtFS.glob_str?("*.rb")).to   be true
      expect(VirtFS.glob_str?("foo.r?")).to be true
    end

    it "should return false when glob characters are escaped" do
      expect(VirtFS.glob_str?("\\*.rb")).to   be false
      expect(VirtFS.glob_str?("foo.r\\?")).to be false
    end
  end

  describe "::dir_and_glob" do
    before(:each) do
      VirtFS.cwd = @this_dir
    end

    it "should return pwd and glob pattern given simple glob pattern" do
      expect(VirtFS.dir_and_glob("*.rb")).to         match_array([ @this_dir, nil, "*.rb" ])
      expect(VirtFS.dir_and_glob("*.d/*.rb")).to     match_array([ @this_dir, nil, "*.d/*.rb" ])
      expect(VirtFS.dir_and_glob("*.d/**/*.rb")).to  match_array([ @this_dir, nil, "*.d/**/*.rb" ])
      expect(VirtFS.dir_and_glob("*.d/src/*.rb")).to match_array([ @this_dir, nil, "*.d/src/*.rb" ])
    end

    it "should return pwd + path and glob pattern given glob pattern with relative path" do
      dir = VfsRealFile.join(@this_dir, "spec")
      expect(VirtFS.dir_and_glob("spec/*.rb")).to         match_array([ dir, "spec", "*.rb" ])
      expect(VirtFS.dir_and_glob("spec/*.d/*.rb")).to     match_array([ dir, "spec", "*.d/*.rb" ])
      expect(VirtFS.dir_and_glob("spec/*.d/**/*.rb")).to  match_array([ dir, "spec", "*.d/**/*.rb" ])
      expect(VirtFS.dir_and_glob("spec/*.d/src/*.rb")).to match_array([ dir, "spec", "*.d/src/*.rb" ])

      dir = VfsRealFile.join(@this_dir, "lib", "spec")
      expect(VirtFS.dir_and_glob("lib/spec/*.rb")).to         match_array([ dir, "lib/spec", "*.rb" ])
      expect(VirtFS.dir_and_glob("lib/spec/*.d/*.rb")).to     match_array([ dir, "lib/spec", "*.d/*.rb" ])
      expect(VirtFS.dir_and_glob("lib/spec/*.d/**/*.rb")).to  match_array([ dir, "lib/spec", "*.d/**/*.rb" ])
      expect(VirtFS.dir_and_glob("lib/spec/*.d/src/*.rb")).to match_array([ dir, "lib/spec", "*.d/src/*.rb" ])
    end

    it "should return pwd and glob pattern given simple glob pattern" do
      dir = VirtFS.normalize_path(VfsRealFile.join(@this_dir, ".."))
      expect(VirtFS.dir_and_glob("../*.rb")).to         match_array([ dir, "..", "*.rb" ])
      expect(VirtFS.dir_and_glob("../*.d/*.rb")).to     match_array([ dir, "..", "*.d/*.rb" ])
      expect(VirtFS.dir_and_glob("../*.d/**/*.rb")).to  match_array([ dir, "..", "*.d/**/*.rb" ])
      expect(VirtFS.dir_and_glob("../*.d/src/*.rb")).to match_array([ dir, "..", "*.d/src/*.rb" ])

      expect(VirtFS.dir_and_glob("dir/../*.rb")).to         match_array([ @this_dir, "dir/..", "*.rb" ])
      expect(VirtFS.dir_and_glob("dir/../*.d/*.rb")).to     match_array([ @this_dir, "dir/..", "*.d/*.rb" ])
      expect(VirtFS.dir_and_glob("dir/../*.d/**/*.rb")).to  match_array([ @this_dir, "dir/..", "*.d/**/*.rb" ])
      expect(VirtFS.dir_and_glob("dir/../*.d/src/*.rb")).to match_array([ @this_dir, "dir/..", "*.d/src/*.rb" ])
    end

    it "should return path and glob pattern given fully qualified glob pattern" do
      expect(VirtFS.dir_and_glob("/bin/*.rb")).to         match_array([ "/bin", "/bin", "*.rb" ])
      expect(VirtFS.dir_and_glob("/bin/*.d/*.rb")).to     match_array([ "/bin", "/bin", "*.d/*.rb" ])
      expect(VirtFS.dir_and_glob("/bin/*.d/**/*.rb")).to  match_array([ "/bin", "/bin", "*.d/**/*.rb" ])
      expect(VirtFS.dir_and_glob("/bin/*.d/src/*.rb")).to match_array([ "/bin", "/bin", "*.d/src/*.rb" ])
    end
  end
end
