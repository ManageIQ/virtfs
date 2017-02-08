require_relative 'thin_io_delegator_methods.rb'

module VirtFS
  # Dispatches File calls to/from VirtFS and the 'Thin' subsystem
  #
  class ThinFileDelegator
    attr_reader :fs_file_obj

    include ThinIODelegatorMethods

    # Instance methods
    def initialize(fs_file_obj, creation_path, fs_path, parsed_args)
      super(fs_file_obj, parsed_args) # Initialize IO instance.
      # @size          = @fs_io_obj.size
      @creation_path = creation_path
      @full_path     = VfsRealFile.join(@fs_io_obj.fs.mount_point, fs_path)
      @fs_path       = fs_path
    end

    def re_initialize(io_obj)
      super(io_obj) # re-initialize IO
      @creation_path = io_obj.instance_variable_get(:@creation_path)
      @full_path     = io_obj.instance_variable_get(:@full_path)
      @fs_path       = io_obj.instance_variable_get(:@fs_path)
    end

    def atime
      file_open
      @fs_io_obj.atime
    end

    def chmod(permission)
      file_open
      @fs_io_obj.chmod(permission)
    end

    def chown(owner, group)
      file_open
      @fs_io_obj.chown(owner, group)
    end

    def ctime
      file_open
      @fs_io_obj.ctime
    end

    def flock(locking_constant)
      file_open
      @fs_io_obj.flock(locking_constant)
    end

    def lstat
      file_open
      @fs_io_obj.lstat
    end

    def mtime
      file_open
      @fs_io_obj.mtime
    end

    def path
      @creation_path
    end
    alias_method :to_path, :path

    def size
      file_open
      @size
    end

    def truncate(len)
      file_open
      @fs_io_obj.truncate(len)
    end
  end
end
