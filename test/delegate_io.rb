require "delegate"

begin

  class MyFile < DelegateClass(::File)
    SUPER_CLASSES = [File, IO]

    def initialize(*args)
      fobj = ::File.new(*args)
      super(fobj)
    end

    def is_a?(klass)
      super(klass) || SUPER_CLASSES.include?(klass)
    end
    alias_method :kind_of?, :is_a?
  end

  f = MyFile.new(__FILE__, "r")

  puts "f.is_a?(File)   = #{f.is_a?(File)}"
  puts "f.is_a?(IO)     = #{f.is_a?(IO)}"
  puts "f.is_a?(MyFile) = #{f.is_a?(MyFile)}"
  puts "f.is_a?(String) = #{f.is_a?(String)}"

  f.close

rescue => err
  puts err.to_s
  puts err.backtrace.join("\n")
end
