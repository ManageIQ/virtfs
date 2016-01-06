begin
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

  File.open("UTF-8-demo.txt", "r:utf-8:utf-8") do |io|
    puts "File opened"
    puts "\tio.pos = #{io.pos}"
    puts

    puts "Reading 10 bytes."
    barray = io.each_byte.first(10)
    puts "\tio.pos = #{io.pos}"
    puts

    puts "Reading 10 bytes."
    barray = io.each_char.first(10)
    puts "\tio.pos = #{io.pos}"
    puts

    puts "Reading 10 lines."
    ln = 0
    io.each_line do |line|
      break if ln >= 10
      puts "Line: #{ln}"
      puts "\tline.length            = #{line.length}"
      puts "\tline.bytesize          = #{line.bytesize}"
      puts "\tline.codepoints.length = #{line.codepoints.length}"
      puts "\tio.pos                 = #{io.pos}"
      puts "\tio.lineno              = #{io.lineno}"
      puts
      ln += 1
    end
  end
rescue => err
  puts err.to_s
  puts err.backtrace.join("\n")
end