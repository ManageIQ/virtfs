require "bundler/gem_tasks"
Dir.glob('tasks/**/*.rake').each(&method(:import))

task :test => :spec
task :default => :spec

require 'yard'

YARD::Rake::YardocTask.new do |t|
 t.files         = ['lib/**/*.rb']
 t.options       = ['--any', '--extra', '--opts']
 t.stats_options = ['--list-undoc']
end
