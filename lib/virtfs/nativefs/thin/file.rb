module VirtFS::NativeFS # rubocop:disable Style/ClassAndModuleChildren
  class Thin
    class File
      attr_reader :fs, :file_obj, :block_size

      def initialize(fs, instance_handle, parsed_args)
        @fs          = fs
        @file_obj    = instance_handle
        @parsed_args = parsed_args
        @block_size  = 512
      end

      def atime
        @file_obj.atime
      end

      def chmod(permission)
        @file_obj.chmod(permission)
      end

      def chown(owner, group)
        @file_obj.chown(owner, group)
      end

      def close
        @file_obj.close unless @file_obj.closed?
      end

      def close_on_exec?
        @file_obj.close_on_exec?
      end

      def close_on_exec=(bool)
        @file_obj.close_on_exec = bool
      end

      def close_read
        @file_obj.close_read
      end

      def close_write
        @file_obj.close_write
      end

      def ctime
        @file_obj.ctime
      end

      def fcntl(cmd, arg)
        @file_obj.fcntl(cmd, arg)
      end

      def fdatasync
        @file_obj.fdatasync
      end

      def flush
        @file_obj.flush
      end

      def fileno
        @file_obj.fileno
      end

      def flock(locking_constant)
        @file_obj.flock(locking_constant)
      end

      def fsync
        @file_obj.fsync
      end

      def isatty
        @file_obj.isatty
      end

      def lstat
        @file_obj.lstat
      end

      def mtime
        @file_obj.mtime
      end

      def pid
        @file_obj.pid
      end

      def raw_read(start_byte, num_bytes)
        @file_obj.sysseek(start_byte, IO::SEEK_SET)
        @file_obj.sysread(num_bytes)
      end

      def raw_write(start_byte, buf)
        @file_obj.sysseek(start_byte, IO::SEEK_SET)
        @file_obj.syswrite(buf)
      end

      def size
        @file_obj.size
      end

      def stat
        @file_obj.stat
      end

      def truncate(len)
        @file_obj.truncate(len)
      end
    end
  end
end
