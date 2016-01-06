require "yaml"

def update_dir(dir)
  dir.instance_variable_set(:@_id, dir.object_id)
end

def dump_load(obj)
  YAML.load(YAML.dump(obj))
end

begin
  dir1 = Dir.new(".")
  puts "dir1.inspect = #{dir1.inspect}"
  puts "dir1.instance_variables = #{dir1.instance_variables}"
  puts

  dir2 = dump_load(dir1)
  puts "dir2.inspect = #{dir2.inspect}"
  puts "dir2.instance_variables = #{dir2.instance_variables}"
  puts

  update_dir(dir1)
  puts "dir1.inspect = #{dir1.inspect}"
  puts "dir1.instance_variables = #{dir1.instance_variables}"
  puts

  dir3 = dump_load(dir1)
  puts "dir3.inspect = #{dir3.inspect}"
  puts "dir3.instance_variables = #{dir3.instance_variables}"
  puts
rescue => err
  puts err.to_s
  puts err.backtrace.join("\n")
end
