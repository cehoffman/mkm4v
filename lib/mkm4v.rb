begin
  # Try to require the preresolved locked set of gems.
  require File.expand_path('../.bundle/environment', __FILE__)
rescue LoadError
  # Fall back on doing an unlocked resolve at runtime.
  require "rubygems"
  require "bundler"
  Bundler.setup
end

require "pathname"

lib = Pathname.new(__FILE__).parent()

require lib + "hacks/kernel"
require lib + "hacks/pathname"
require lib + "mkm4v/version"
require lib + "mkm4v/opts"
require lib + "mkm4v/cli"