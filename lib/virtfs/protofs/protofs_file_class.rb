#
# File class methods - are instance methods of filesystem instance.
#
class ProtoFS
  def file_atime(p)
  end

  def file_blockdev?(p)
  end

  def file_chardev?(p)
  end

  def file_chmod(permission, p)
  end

  def file_chown(owner, group, p)
  end

  def file_fileCtime(p)
  end

  def file_delete(p)
  end

  def file_directory?(p)
  end

  def file_executable?(p)
  end

  def file_executable_real?(p)
  end

  def file_exist?(p)
  end

  def file_file?(p)
  end

  def file_ftype(p)
  end

  def file_grpowned?(p)
  end

  def file_identical?(p1, p2)
  end

  def file_lchmod(permission, p)
  end

  def file_lchown(owner, group, p)
  end

  def file_link(p1, p2)
  end

  def file_lstat(p)
  end

  def file_mtime(p)
  end

  def file_owned?(p)
  end

  def file_pipe?(p)
  end

  def file_readable?(p)
  end

  def file_readable_real?(p)
  end

  def file_readlink(p)
  end

  def file_rename(p1, p2)
  end

  def file_setgid?(p)
  end

  def file_setuid?(p)
  end

  def file_size(p)
  end

  def file_socket?(p)
  end

  def file_stat(p)
  end

  def file_sticky?(p)
  end

  def file_symlink(oname, p)
  end

  def file_symlink?(p)
  end

  def file_truncate(p, len)
  end

  def file_utime(atime, mtime, p)
  end

  def file_world_readable?(p, len)
  end

  def file_world_writable?(p, len)
  end

  def file_writable?(p, len)
  end

  def file_writable_real?(p, len)
  end

  def file_new(f, parsed_args)
    File.new(self, lookup_file(f), parsed_args)
  end

  private

  def lookup_file(f)
    #
    # Get filesystem-specific handel for file instance.
    #
  end
end
