begin
  #
  # Find the offset within the file of the first multi-byte character.
  #
  first_mb_char_pos = 0
  File.open("UTF-8-demo.txt", "r:utf-8:utf-8") do |io|
    io.each_char do |c|
      if c.length != c.bytesize
        puts "first_mb_char_pos = #{first_mb_char_pos}, char = '#{c}' #{c.bytes.to_a.inspect}"
        puts
        break
      end
      first_mb_char_pos += 1
    end
  end

  puts "Read whole file as binary:"
  binary_string = ""
  File.open("UTF-8-demo.txt", "rb") do |io|
    binary_string = io.read
  end
  puts "\tbinary_string.encoding.name   = #{binary_string.encoding.name} (valid: #{binary_string.valid_encoding?})"
  puts "\tbinary_string.length          = #{binary_string.length}"
  puts "\tbinary_string.bytesize        = #{binary_string.bytesize}"
  puts

  puts "Read whole file as utf-8:"
  utf8_string = ""
  File.open("UTF-8-demo.txt", "r:utf-8:utf-8") do |io|
    utf8_string = io.read
  end
  puts "\tutf8_string.encoding.name   = #{utf8_string.encoding.name} (valid: #{utf8_string.valid_encoding?})"
  puts "\tutf8_string.length          = #{utf8_string.length}"
  puts "\tutf8_string.bytesize        = #{utf8_string.bytesize}"
  puts

  puts "Partial read (100 bytes) as utf-8:"
  File.open("UTF-8-demo.txt", "r:utf-8:utf-8") do |io|
    utf8_string = io.read(100)
  end
  puts "\tutf8_string.encoding.name   = #{utf8_string.encoding.name} (valid: #{utf8_string.valid_encoding?})"
  puts "\tutf8_string.length          = #{utf8_string.length}"
  puts "\tutf8_string.bytesize        = #{utf8_string.bytesize}"
  puts

  puts "Offset read (on char boundary) as utf-8:"
  File.open("UTF-8-demo.txt", "r:utf-8:utf-8") do |io|
    io.seek(first_mb_char_pos, IO::SEEK_SET)
    utf8_string = io.read
  end
  puts "\tutf8_string.encoding.name   = #{utf8_string.encoding.name} (valid: #{utf8_string.valid_encoding?})"
  puts "\tutf8_string.length          = #{utf8_string.length}"
  puts "\tutf8_string.bytesize        = #{utf8_string.bytesize}"
  puts

  puts "Offset read (not on char boundary) as utf-8:"
  File.open("UTF-8-demo.txt", "r:utf-8:utf-8") do |io|
    io.seek(first_mb_char_pos+1, IO::SEEK_SET)
    utf8_string = io.read
  end
  puts "\tutf8_string.encoding.name   = #{utf8_string.encoding.name} (valid: #{utf8_string.valid_encoding?})"
  puts "\tutf8_string.length          = #{utf8_string.length}"
  puts "\tutf8_string.bytesize        = #{utf8_string.bytesize}"
  puts

  # File.open("UTF-8-demo.txt", "r:utf-8:utf-8") do |io|
  #   while utf8_string = io.gets
  #     puts utf8_string
  #     puts "\tutf8_string.encoding.name   = #{utf8_string.encoding.name} (valid: #{utf8_string.valid_encoding?})"
  #     puts "\tutf8_string.length          = #{utf8_string.length}"
  #     puts "\tutf8_string.bytesize        = #{utf8_string.bytesize}"
  #     puts
  #   end
  # end
rescue => err
  puts err.to_s
  puts err.backtrace.join("\n")
end
