module VirtFS
  class VIO # rubocop:disable ClassLength
    include IOInstanceDelegate

    VfsRealIO.constants.each { |cn| const_set(cn, VfsRealIO.const_get(cn)) }

    def initialize(io_obj)
      __setobj__(io_obj)
    end

    #
    # Some methods need to return the IO object. Methods in the delegator
    # object can't do that, so we intercept them and do it here.
    #

    def <<(obj)
      super
      self
    end

    def binmode
      super
      self
    end

    def reopen(*args)
      __setobj__(super)
      self
    end

    def set_encoding(*args) # rubocop:disable Style/AccessorMethodName
      super
      self
    end

    def to_io
      self
    end

    # Class methods
    class << self
      def binread(f, length = nil, offset = 0)
        VFile.open(f, "rb") do |fobj|
          fobj.pos = offset
          return fobj.read unless length
          return fobj.read(length)
        end
      end

      # def binwrite()

      def copy_stream(from, to, max_length = nil, offset = 0) # rubocop:disable CyclomaticComplexity
        from_file = from.is_a?(VIO) ? from : VFile.open(from, "rb")
        to_file   = to.is_a?(VIO)   ? to   : VFile.open(to, "wb") # rubocop:disable SpaceAroundOperators
        return copy_from_to(from_file, to_file, max_length, offset)
      ensure
        from_file.close unless from_file.nil? || from.is_a?(VIO)
        to_file.close   unless to_file.nil?   || to.is_a?(VIO)    # rubocop:disable SpaceAroundOperators
      end

      #
      # IO.foreach( portname, separator=$/ <, options> ) { | line | . . . } -> nil
      # IO.foreach( portname, limit <, options> ) { | line | . . . } -> nil
      # IO.foreach( portname, separator, limit <, options> ) { | line | . . . } -> nil
      #
      def foreach(portname, *args, &block)
        return VfsRealIO.foreach(portname, *args) unless filename?(portname)
        return to_enum(__method__, portname, *args) unless block_given?

        separator, limit, options = parse_args(args)

        VFile.open(portname, "r", options) do |fobj|
          fobj.each(separator, limit, &block)
        end
        nil
      end

      def pipe(*args, &block)
        # XXX - should wrap VfsRealIO objects in common delegator class
        # so is_a? and kind_of? will work with all IO objects.
        VfsRealIO.pipe(*args, &block) # TODO: wrap returned read and write IO
      end

      def popen(*args, &block)
        VfsRealIO.popen(*args, &block) # TODO: wrap returned IO
      end

      def read(portname, *args)
        return VfsRealIO.read(portname, *args) unless filename?(portname)

        length, offset, options = length_offset_options(args)

        VFile.open(portname, "r", options) do |fobj|
          fobj.pos = offset
          return fobj.read unless length
          return fobj.read(length)
        end
      end

      def readlines(portname, *args)
        return VfsRealIO.readlines(portname, *args) unless filename?(portname)
        foreach(portname, *args).to_a
      end

      def select(*args)
        VfsRealIO.select(*args)
      end

      def sysopen(*args)
        VfsRealIO.sysopen(*args)
      end

      def try_convert(obj)
        return nil unless obj.respond_to?(:to_io)
        obj.to_io # TODO: wrap?
      end

      #
      # Instantiate IO instance.
      #

      def new(integer_fd, mode = "r", hash_options = {})
        #
        # Directly instantiating an IO instance (not through File)
        # will return a standard IO object.
        #
        fs_obj = VfsRealIO.new(integer_fd, mode, hash_options)
        obj = allocate
        obj.send(:initialize, fs_obj)
        obj
      end
      alias_method :for_fd, :new

      def open(*args)
        io_obj = new(*args) # IO.new or File.new
        return io_obj unless block_given?
        begin
          return yield(io_obj)
        ensure
          io_obj.close
        end
      end

      private

      def filename?(portname)
        portname[0] != "|"
      end

      # separator, limit, options
      def parse_args(args)
        separator = $RS
        limit = nil
        options = {}

        while (arg = args.shift)
          if arg.is_a?(String)
            separator = arg
          elsif arg.is_a?(Numeric)
            limit = arg
          elsif arg.is_a?(Hash)
            options = arg
          end
        end
        return separator, limit, options
      end

      def length_offset_options(args) # rubocop:disable AbcSize, PerceivedComplexity, CyclomaticComplexity
        case args.length
        when 0
          return nil, 0, {}
        when 1
          return args[0].to_int, 0, {} if args[0].respond_to?(:to_int)
          return nil, 0, args[0].to_hash if args[0].respond_to?(:to_hash)
          int_type_error(args[0])
        when 2
          int_type_error(args[0]) unless args[0].respond_to?(:to_int)
          return args[0].to_int, args[1].to_int, {} if args[1].respond_to?(:to_int)
          return args[0].to_int, 0, args[1].to_hash if args[1].respond_to?(:to_hash)
          int_type_error(args[1])
        when 3
          int_type_error(args[0]) unless args[0].respond_to?(:to_int)
          int_type_error(args[1]) unless args[1].respond_to?(:to_int)
          return args[0].to_int, args[1].to_int, args[2].to_hash if args[2].respond_to?(:to_hash)
          hash_type_error(args[2])
        else
          raise ArgumentError, "wrong number of arguments (5+ for 1..4)"
        end
      end

      def int_type_error(arg)
        raise TypeError, "no implicit conversion from #{arg.class.name} to integer"
      end

      def hash_type_error(arg)
        raise TypeError, "no implicit conversion from #{arg.class.name} to Hash"
      end

      def copy_from_to(from, to, length, offset)
        chunk_size    = 1024
        bytes_written = 0

        from.pos = offset
        while (rv = from.read(chunk_size))
          if length && bytes_written + rv.bytesize > length
            len = length - bytes_written
            to.write(rv[0, len])
            break
          end
          to.write(rv)
          bytes_written += rv.bytesize
        end
        bytes_written
      end
    end # class methods
  end
end
