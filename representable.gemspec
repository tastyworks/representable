# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'representable/version'

Gem::Specification.new do |s|
  s.name        = "tastyworks-representable"
  s.version     = Representable::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Nick Sutterer", "tastyworks"]
  s.email       = ["apotonick@gmail.com", "developers@tastyworks.com"]
  s.homepage    = "https://github.com/tastyworks/representable"
  s.summary     = %q{Renders and parses JSON/XML/YAML documents from and to Ruby objects. Includes plain properties, collections, nesting, coercion and more.}
  s.description = s.summary

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.license       = "MIT"

  s.add_dependency "uber", "~> 0.0.7"

  s.add_development_dependency "rake"
  s.add_development_dependency "test_xml", "0.1.6"
  s.add_development_dependency "minitest", ">= 5.4.1"
  s.add_development_dependency "mongoid"
  s.add_development_dependency "virtus"
  s.add_development_dependency "json", '>= 1.7.7'

  s.add_development_dependency "ruby-prof"

  s.add_development_dependency 'package_cloud', '0.2.29'
end
