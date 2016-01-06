require "yaml"

begin
  begin
    Dir.new("/not/a/dir")
  rescue => err
    puts " err => #{err.class.name}"
    puts " err => #{err.inspect}"
    puts " err.errno = #{err.errno}"
    puts " err.class::Errno = #{err.class::Errno}"
    err = YAML.load(YAML.dump(err))
    nerr = SystemCallError.new("dir", err.class::Errno)
    # nerr.message = err.message
    raise nerr
  end
rescue Errno::ENOENT => oerr
  puts "**** Got Errno::ENOENT"
  puts "oerr => #{oerr.class.name}"
  puts "oerr => #{oerr.inspect}"
  puts "oerr.errno = #{oerr.errno}"
  puts "oerr.class::Errno = #{oerr.class::Errno}"
rescue SystemCallError => oerr
  puts "**** Got SystemCallError"
rescue => oerr
  puts "**** Not Errno::ENOENT"
  puts "oerr => #{oerr.class.name}"
  puts "oerr => #{oerr.inspect}"
  puts "oerr.errno = #{oerr.errno}"
  puts "oerr.class::Errno = #{oerr.class::Errno}"
end
