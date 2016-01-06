begin
  utf8_string = ""
  bin_string  = ""

  puts "Read UTF-8 file, returning UTF-8"
  File.open("utf-8-demo.txt", "r:UTF-8:UTF-8") do |io|
    utf8_string = io.read
  end
  puts "\tutf8_string.encoding.name   = #{utf8_string.encoding.name} (valid: #{utf8_string.valid_encoding?})"
  puts "\tutf8_string.length          = #{utf8_string.length}"
  puts "\tutf8_string.bytesize        = #{utf8_string.bytesize}"
  puts

  puts "Transcode UTF-8 to UTF-16"
  utf16_string = utf8_string.encode("UTF-16le")
  puts "\tutf16_string.encoding.name   = #{utf16_string.encoding.name} (valid: #{utf16_string.valid_encoding?})"
  puts "\tutf16_string.length          = #{utf16_string.length}"
  puts "\tutf16_string.bytesize        = #{utf16_string.bytesize}"
  puts

  File.open("utf-16-demo.txt", "wb") do |io|
    io.write(utf16_string)
  end

  puts "Read UTF-8 file, returning UTF-16"
  File.open("utf-8-demo.txt", "r:UTF-8:UTF-16le") do |io|
    utf16_string = io.read
  end
  puts "\tutf16_string.encoding.name   = #{utf16_string.encoding.name} (valid: #{utf16_string.valid_encoding?})"
  puts "\tutf16_string.length          = #{utf16_string.length}"
  puts "\tutf16_string.bytesize        = #{utf16_string.bytesize}"
  puts

  puts "Read UTF-16 file, as binary"
  File.open("utf-16-demo.txt", "rb") do |io|
    bin_string = io.read
  end
  puts "\tbin_string.encoding.name   = #{bin_string.encoding.name} (valid: #{bin_string.valid_encoding?})"
  puts "\tbin_string.length          = #{bin_string.length}"
  puts "\tbin_string.bytesize        = #{bin_string.bytesize}"
  puts

  puts "Force encode binary to UTF-16"
  bin_string.force_encoding("UTF-16le")
  puts "\tbin_string.encoding.name   = #{bin_string.encoding.name} (valid: #{bin_string.valid_encoding?})"
  puts "\tbin_string.length          = #{bin_string.length}"
  puts "\tbin_string.bytesize        = #{bin_string.bytesize}"
  puts

  puts "Transcode UTF-16 to UTF-8"
  utf8_string = bin_string.encode("UTF-8")
  puts "\tutf8_string.encoding.name   = #{utf8_string.encoding.name} (valid: #{utf8_string.valid_encoding?})"
  puts "\tutf8_string.length          = #{utf8_string.length}"
  puts "\tutf8_string.bytesize        = #{utf8_string.bytesize}"
  puts

  puts "Read UTF-16 file, returning UTF-8"
  File.open("utf-16-demo.txt", "r:UTF-16le:UTF-8") do |io|
    utf16_string = io.read
  end
  puts "\tutf16_string.encoding.name   = #{utf16_string.encoding.name} (valid: #{utf16_string.valid_encoding?})"
  puts "\tutf16_string.length          = #{utf16_string.length}"
  puts "\tutf16_string.bytesize        = #{utf16_string.bytesize}"
  puts

  puts "Read UTF-16 file, returning UTF-16"
  File.open("utf-16-demo.txt", "r:UTF-16le:UTF-16le") do |io|
    utf16_string = io.read
  end
  puts "\tutf16_string.encoding.name   = #{utf16_string.encoding.name} (valid: #{utf16_string.valid_encoding?})"
  puts "\tutf16_string.length          = #{utf16_string.length}"
  puts "\tutf16_string.bytesize        = #{utf16_string.bytesize}"
  puts
rescue => err
  puts err.to_s
  puts err.backtrace.join("\n")
end
