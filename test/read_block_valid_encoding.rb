require "tempfile"

begin
  input_file_name   = "UTF-8-demo.txt"
  external_encoding = Encoding.find("UTF-8")
  binary_encoding   = Encoding.find("ASCII-8BIT")
  buffer_size       = 95

  temp_file  = Tempfile.new("rbve")

  File.open(input_file_name, "rb") do |io|
    block = 0
    while (binary_string = io.read(buffer_size))
      binary_string.force_encoding(external_encoding)
      puts "Block: #{block}, valid: #{binary_string.valid_encoding?}"
      push_back = 0
      (0...8).each do
        break if binary_string.valid_encoding?
        binary_string.force_encoding(binary_encoding)
        binary_string[-1] = ""
        binary_string.force_encoding(external_encoding)
        push_back += 1
      end
      raise "Invalid byte sequence" unless binary_string.valid_encoding?
      puts "Block: #{block}, valid: #{binary_string.valid_encoding?}, push_back: #{push_back}"
      temp_file.write(binary_string)
      io.seek(-push_back, IO::SEEK_CUR) unless push_back == 0
      block += 1
    end
  end

  temp_file.close

  input  = File.read(input_file_name)
  output = File.read(temp_file.path)

  puts
  puts "Input size:  #{input.bytesize}"
  puts "Output size: #{output.bytesize}"
  puts "Data check pass: #{input == output}"
rescue => err
  puts err.to_s
  puts err.backtrace.join("\n")
end
