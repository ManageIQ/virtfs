require "../lib/virtfs"
require "tempfile"

begin
  @start_marker = "START OF FILE:\n"
  @end_marker   = ":END OF FILE"
  @data1        = "0123456789"
  @data2        = "abcdefghijklmnopqrstuvwxyz\n"

  @temp_file    = Tempfile.new("VirtFS-IO")
  @temp_file.write(@start_marker)
  (0..9).each do
    @temp_file.write(@data1)
    @temp_file.write(@data2)
  end
  @temp_file.write(@end_marker)
  @temp_file.close

  @full_path  = @temp_file.path
  @rel_path   = File.basename(@full_path)
  @parent_dir = File.dirname(@full_path)
  @file_size  = VfsRealFile.size(@full_path)

  @utf_8_filename  = VfsRealFile.join(__dir__, "UTF-8-demo.txt")

  require "../lib/nativefs"
  @root      = File::SEPARATOR
  @native_fs = NativeFS.new
  VirtFS.mount(@native_fs, @root)

  @vfile_read_obj = VirtFS::VFile.new(@full_path, "r:UTF-8")
  @vfile_read_obj.send(:min_read_buf_sz=, 1)
  range = @vfile_read_obj.read_buffer.range

  puts "pos = #{@vfile_read_obj.pos}, Range(#{range.first}, #{range.end})"

  char = "X"
  @vfile_read_obj.ungetc(char)
  puts "pos = #{@vfile_read_obj.pos}, Range(#{range.first}, #{range.end})"
  @vfile_read_obj.getc

rescue => err
  puts err.to_s
  puts err.backtrace.join("\n")
end
