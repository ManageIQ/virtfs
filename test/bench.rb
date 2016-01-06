big_string = "0123456789" * 1000
big_string.force_encoding("ASCII-8BIT")

t0 = Time.now
(0...2_000_000).each do
  s = big_string.dup
  s[-1] = ""
end
t1 = Time.now
puts "Index: #{t1 - t0} seconds"

t0 = Time.now
(0...2_000_000).each do
  s = big_string.dup
  s.chop!
end
t1 = Time.now
puts "chop!: #{t1 - t0} seconds"
