# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'virtfs/version'

Gem::Specification.new do |spec|
  spec.name          = "virtfs"
  spec.version       = VirtFS::VERSION
  spec.authors       = ["Richard Oliveri"]
  spec.email         = ["roliveri@redhat.com"]

  spec.summary       = "Virtual filesystem facility for Ruby"
  spec.description   = %q{
    Supports "pluggable" filesystem modules - instances of which,
    can be mounted anywhere in the global filesystem namespace of the Ruby process.
  }
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
