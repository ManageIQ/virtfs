require "tmpdir"
require "tempfile"
require "find"
require "virtfs"

if ENV['FS_INTERFACE'] && ENV['FS_INTERFACE'].downcase == "thick"
  $fs_interface = "Thick"
  require "virtfs-nativefs-thick"
else
  $fs_interface = "Thin"
  require "virtfs-nativefs-thin"
end

def nativefs_class
  if $fs_interface == "Thin"
    VirtFS::NativeFS::Thin
  else
    VirtFS::NativeFS::Thick
  end
end

def reset_context
  VirtFS.deactivate! if VirtFS.activated?
  VirtFS.context_manager.reset_all
end

def buffer_test_sizes
  [1024 * 32, 1]
end

def temp_name(pfx = "", sfx = "")
  VfsRealDir::Tmpname.create([pfx, sfx]) {}
end

def block_dev_file
  dev_dir = "/dev"
  return nil unless VfsRealDir.exist?(dev_dir)
  Find.find(dev_dir) do |f|
    next unless VfsRealFile.blockdev?(f)
    return f
  end
  nil
end

def char_dev_file
  dev_dir = "/dev"
  return nil unless VfsRealDir.exist?(dev_dir)
  Find.find(dev_dir) do |f|
    next unless VfsRealFile.chardev?(f)
    return f
  end
  nil
end

def suppress_warnings
  original_verbosity = $VERBOSE
  $VERBOSE = nil
  result = yield
  $VERBOSE = original_verbosity
  result
end
