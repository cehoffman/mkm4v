# -*- encoding: utf-8 -*-
require File.expand_path('../lib/mkm4v/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Chris Hoffman"]
  gem.email         = ["cehoffman@gmail.com"]
  gem.description   = %q{Mkm4v automates the process of converting movies and tv shows for viewing on the Apple TV. This process involves the conversion of DTS tracks to AC3, scanning of forced subtitle tracks, and automatic inclusion of subtitles when audio is not native language.}
  gem.summary       = %q{Mkm4v automates the process of converting movies and tv shows for viewing on the Apple TV}
  gem.homepage      = ""

  gem.add_runtime_dependency 'fraction', '~> 0.1'
  gem.add_runtime_dependency 'trollop', '~> 1.15'
  gem.add_runtime_dependency 'plist', '~> 3.1.0'
  gem.add_runtime_dependency 'iso-639', '~> 0.0.2'

  gem.add_development_dependency 'ronn', '~> 0.7.3'
  gem.add_development_dependency 'rspec', '~> 2.9.0'
  gem.add_development_dependency 'rake-compiler', '~> 0.8.0'
  gem.add_development_dependency 'fakefs', '~> 0.4.0'

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.extensions    = `git ls-files -- ext/*/extconf.rb`.split(?\n)
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "mkm4v"
  gem.require_paths = ["lib"]
  gem.version       = Mkm4v::VERSION
end
