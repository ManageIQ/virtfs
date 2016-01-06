module VirtFS
  #
  # *args --> mode="r" <,permission> <,options>
  #           mode       --> String or Integer
  #           permission --> Integer
  #           options    --> Hash
  #
  # 1 arg:  <mode | options>
  # 2 args: mode, <permissions | options>
  # 3 args: mode, permissions, options
  #
  # mode string --> file-mode[:external-encoding[:internal-encoding]]
  #
  # file-mode mapped to binary:
  #     "r"  --> File::RDONLY
  #     "r+" --> File::RDWR
  #     "w"  --> File::WRONLY | File::TRUNC  | File::CREAT
  #     "w+" --> File::RDWR   | File::TRUNC  | File::CREAT
  #     "a"  --> File::WRONLY | File::APPEND | File::CREAT
  #     "a+" --> File::RDWR   | File::APPEND | File::CREAT
  #
  # Options:
  #     :autoclose          => If false, the underlying file will not be closed
  #                            when this I/O object is finalized.
  #
  #     :binmode            => Opens the IO object in binary mode if true (same as mode: "b").
  #
  #     :encoding           => Specifies both external and internal encodings
  #                            as "external:internal" (same format used in mode parameter).
  #
  #     :external_encoding  => Specifies the external encoding.
  #
  #     :internal_encoding  => Specifies the internal encoding.
  #
  #     :mode               => Specifies what would have been the mode parameter.
  #
  #     :textmode           => Open the file in text mode (the default).
  #
  class FileModesAndOptions
    attr_reader :external_encoding, :external_encoding_str
    attr_reader :internal_encoding, :internal_encoding_str
    attr_reader :permissions, :mode_bits, :options
    attr_reader :args

    BINARY_ENCODING = "ASCII-8BIT"

    def initialize(*args)
      @args      = args
      @options   = {}
      @mode_bits = 0
      @external_encoding_str = ""
      @internal_encoding_str = ""
      @binmode     = false
      @autoclose   = true
      @permissions = nil
      @closed      = false

      process_args(args)

      @mode_bits = VFile::RDONLY if @mode_bits == 0

      if @external_encoding_str.empty?
        @external_encoding = Encoding.default_external
      else
        @external_encoding = Encoding.find(@external_encoding_str)
      end

      if @internal_encoding_str.empty?
        @internal_encoding = Encoding.default_internal
      else
        @internal_encoding = Encoding.find(@internal_encoding_str)
      end
    end

    def [](key)
      @options[key]
    end

    def append?
      @mode_bits & VFile::APPEND != 0
    end

    def autoclose?
      @autoclose
    end

    def binmode?
      @binmode
    end

    def binmode
      set_encoding(BINARY_ENCODING, nil)
      @binmode = true
    end

    def closed?
      @closed
    end

    def create?
      @mode_bits & VFile::CREAT != 0
    end

    def excl?
      @mode_bits & VFile::EXCL != 0
    end

    def noctty?
      @mode_bits & VFile::NOCTTY != 0
    end

    def nonblock?
      @mode_bits & VFile::NONBLOCK != 0
    end

    def rdonly?
      @mode_bits == VFile::RDONLY # VFile::RDONLY = 0
    end

    def rdwr?
      @mode_bits & VFile::RDWR != 0
    end

    def trunc?
      @mode_bits & VFile::TRUNC != 0
    end

    def wronly?
      @mode_bits & VFile::WRONLY != 0
    end

    def read?
      rdonly? || rdwr?
    end

    def write?
      wronly? || rdwr?
    end

    def close_read
      return unless rdonly?
      close
    end

    def close_write
      return unless wronly?
      close
    end

    def close
      @closed = true
    end

    def set_encoding(*args)
      raise ArgumentError, "wrong number of arguments (#{args.length} for 1..2)" if args.length < 1 || args.length > 2
      unless args[0].is_a?(Encoding) || args[0].respond_to?(:to_str)
        raise TypeError, "no implicit conversion of #{args[0].class.name} into String"
      end

      if args.length == 2
        unless args[1].is_a?(Encoding) || args[1].respond_to?(:to_str) || args[1].nil?
          raise TypeError, "no implicit conversion of #{args[1].class.name} into String"
        end
        @external_encoding     = args[0].is_a?(Encoding) ? args[0] : Encoding.find(args[0].to_str)
        @internal_encoding     = args[1].nil? || args[1].is_a?(Encoding) ? args[1] : Encoding.find(args[1].to_str)
        return nil
      end

      if args[0].is_a?(Encoding)
        @external_encoding = args[0]
        return nil
      end

      if args[0].to_str.include?(":")
        @external_encoding_str, @internal_encoding_str = args[0].split(":")
        @external_encoding_str = @external_encoding_str.to_str
        @internal_encoding_str = @internal_encoding_str.to_str
      else
        @external_encoding_str = @internal_encoding_str = args[0].to_str
      end

      @external_encoding = Encoding.find(@external_encoding_str) unless @external_encoding_str.empty?
      @internal_encoding = Encoding.find(@internal_encoding_str) unless @internal_encoding_str.empty?
      nil
    end
    
    private

    def process_args(args)
      case args.length
      when 0
        # mode = "r"
      when 1
        # <mode | options>
        if args[0].is_a?(Hash)
          @options = args[0]
        else
          mode_arg(args[0])
        end
      when 2
        # mode, <permissions | options>
        mode_arg(args[0])
        if args[1].is_a?(Hash)
          @options = args[1]
        else
          @permissions = args[1].to_int
        end
      when 3
        # mode, permissions, options
        mode_arg(args[0])
        @permissions = args[1].to_int
        @options = args[2]
        raise ArgumentError, "wrong number of arguments (4 for 1..3)" unless @options.is_a?(Hash)
      end
      process_options(@options)
    end

    def mode_arg(mode)
      if mode.respond_to?(:to_int)
        @mode_bits = mode.to_int
      else
        @mode_string = mode.to_str
        @file_mode, external_encoding_str, internal_encoding_str = @mode_string.split(":")

        unless external_encoding_str.nil? || external_encoding_str.empty?
          raise ArgumentError, "encoding specified twice" unless @external_encoding_str.empty?
          @external_encoding_str = external_encoding_str.to_s
        end
        unless internal_encoding_str.nil? || internal_encoding_str.empty?
          raise ArgumentError, "encoding specified twice" unless @internal_encoding_str.empty?
          @internal_encoding_str = internal_encoding_str.to_s
        end

        mode_str_to_bits(@file_mode)
      end
      @mode_provided = true
    end

    def mode_str_to_bits(mode_str)
      if mode_str[-1] == "b"
        binmode
        mode_str[-1] = ""
        return if mode_str.empty?
      end

      @mode_bits = case mode_str
                   when "r"  then VFile::RDONLY
                   when "r+" then VFile::RDWR
                   when "w"  then VFile::WRONLY | VFile::TRUNC | VFile::CREAT
                   when "w+" then VFile::RDWR | VFile::TRUNC | VFile::CREAT
                   when "a"  then VFile::WRONLY | VFile::APPEND | VFile::CREAT
                   when "a+" then VFile::RDWR | VFile::APPEND | VFile::CREAT
                   else
                     raise ArgumentError, "invalid access mode #{mode_str}"
                   end
    end

    def process_options(opts)
      return if opts.empty?

      @autoclose = opts[:autoclose] if opts.key?(:autoclose)
      if opts.key?(:binmode)
        raise ArgumentError, "binmode specified twice" if binmode?
        binmode
      end
      if opts[:encoding]
        raise ArgumentError, "encoding specified twice" unless @external_encoding_str.empty? && @internal_encoding_str.empty?
        @external_encoding_str, @internal_encoding_str = opts[:encoding].split(":")
        @external_encoding_str = @external_encoding_str.to_s
        @internal_encoding_str = @internal_encoding_str.to_s
      end
      if opts[:external_encoding]
        raise ArgumentError, "encoding specified twice" unless @external_encoding_str.empty?
        @external_encoding_str = opts[:external_encoding].dup
      end
      if opts[:internal_encoding]
        raise ArgumentError, "encoding specified twice" unless @internal_encoding_str.empty?
        @internal_encoding_str = opts[:internal_encoding]
      end
      if opts[:mode]
        raise ArgumentError, "mode specified twice" if @mode_provided
        mode_arg(opts[:mode])
      end
      if opts.key?(:textmode)
        raise ArgumentError, "binmode and textmode are mutually exclusive" if binmode?
      end
      nil
    end
  end
end
