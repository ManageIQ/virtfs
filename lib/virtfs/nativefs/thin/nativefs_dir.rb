module VirtFS::NativeFS # rubocop:disable Style/ClassAndModuleChildren
  class Thin
    class Dir
      attr_reader :fs, :dir_obj

      def initialize(fs, instance_handle, hash_args)
        @fs        = fs
        @dir_obj   = instance_handle
        @hash_args = hash_args

        @cache     = nil
      end

      def close
        @dir_obj.close
      end

      # returns file_name and new position.
      def read(pos)
        return cache[pos], pos + 1
      end

      private

      def cache
        @cache ||= @dir_obj.each.to_a
      end
    end
  end
end
