#
# Dir class methods - are instance methods of filesystem instance.
#
class ProtoFS
  def dir_delete(p)
  end

  def dir_entries(p)
  end

  def dir_exist?(p)
  end

  def dir_foreach(p, &block)
  end

  def dir_mkdir(p, permissions)
  end

  def dir_new(dir, hash_args={})
    Dir.new(self, lookup_dir(dir), hash_args)
  end

  private

  def lookup_dir(dir)
    #
    # Get filesystem-specific handel for directory instance.
    #
  end
end
