begin
  #
  # Find the offset within the file of the first multi-byte character.
  #
  binary_string = ""
  File.open("UTF-16-demo.txt", "rb") do |io|
    binary_string = io.read
  end
  puts "\tbinary_string.encoding.name   = #{binary_string.encoding.name} (valid: #{binary_string.valid_encoding?})"
  puts "\tbinary_string.length          = #{binary_string.length}"
  puts "\tbinary_string.bytesize        = #{binary_string.bytesize}"
  puts

  utf8_string = ""
  ec = Encoding::Converter.new("UTF-16le", "UTF-8")
  rv = ec.primitive_convert(binary_string, utf8_string)
  puts "primitive_convert --> #{rv}"
  puts "\tutf8_string.encoding.name   = #{utf8_string.encoding.name} (valid: #{utf8_string.valid_encoding?})"
  puts "\tutf8_string.length          = #{utf8_string.length}"
  puts "\tutf8_string.bytesize        = #{utf8_string.bytesize}"
  puts

  nchunk = 0
  utf8_string = ""
  ec = Encoding::Converter.new("UTF-16le", "UTF-8")
  File.open("UTF-16-demo.txt", "rb") do |io|
    while (binary_string = io.read(99))
      rv = ec.primitive_convert(binary_string, utf8_string, nil, nil, :partial_input => true)
      puts "Chunk: #{nchunk}, rv = #{rv}"
      nchunk += 1
    end
  end

  puts "nchunk = #{nchunk}"
  puts "\tutf8_string.encoding.name   = #{utf8_string.encoding.name} (valid: #{utf8_string.valid_encoding?})"
  puts "\tutf8_string.length          = #{utf8_string.length}"
  puts "\tutf8_string.bytesize        = #{utf8_string.bytesize}"
  puts
rescue => err
  puts err.to_s
  puts err.backtrace.join("\n")
end
