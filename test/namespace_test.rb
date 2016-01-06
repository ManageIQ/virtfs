class MyFile
  def self.name
    "MyFile"
  end
end

class Vfs
  def self.nest(ext)
    ext.const_set(:File, MyFile)
  end
end

begin

  Module.new do
    class << self
      puts self.class.name
      puts constants.inspect
      puts File.name

      Vfs.nest(self)
      puts constants.inspect
      puts File.name
    end
  end

  puts

  Module.new do
    class << self
      puts self.class.name
      puts constants.inspect
      puts File.name
    end
  end

  puts File.name

rescue => err
  puts err.to_s
  puts err.backtrace.join("\n")
end
