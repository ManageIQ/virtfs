module VirtFS
  # ByteRange utility class, encapsulate a range of bytes as given
  # by their first / last offsets
  class ByteRange
    attr_accessor :first, :last

    def initialize(first = nil, last = nil)
      set(first, last)
    end

    def empty?
      @first.nil? || @last.nil?
    end

    def length
      return 0 if empty?
      @last - @first + 1
    end

    def include?(obj)
      return false if empty?
      return (obj.first >= @first && obj.last <= @last) if obj.is_a?(self.class)
      obj >= @first && obj <= @last
    end

    def adjacent?(*args)
      return false if empty?
      nrange = range_arg(args)
      nrange.first == @last + 1 || nrange.last == @first - 1
    end

    def overlap?(*args)
      return false if empty?
      nrange = range_arg(args)
      include?(nrange.first) || include?(nrange.last) || nrange.include?(@first) || nrange.include?(@last)
    end

    def contiguous?(*args)
      nrange = range_arg(args)
      adjacent?(nrange) || overlap?(nrange)
    end

    def expand(*args)
      nrange = range_arg(args)
      @first = nrange.first if empty? || nrange.first < @first
      @last  = nrange.last  if empty? || nrange.last  > @last
    end

    def clear
      set(nil, nil)
    end

    def set(first, last)
      @first = first
      @last  = last
    end

    private

    def range_arg(args)
      case args.length
      when 1
        return args[0]
      when 2
        return self.class.new(args[0], args[1])
      else
        raise ArgumentError, "wrong number of arguments (#{args.length} for 1..2)"
      end
    end
  end
end
