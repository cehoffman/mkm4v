begin
  # Try to require the preresolved locked set of gems.
  require File.expand_path('../../.bundle/environment', __FILE__)
rescue LoadError
  # Fall back on doing an unlocked resolve at runtime.
  require "rubygems"
  require "bundler"
  Bundler.setup
end

require "spec"

$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require "mkm4v"
require "ruby-debug"
require "fileutils"
require "fakefs"
require "fakefs/spec_helpers"
FakeFS.deactivate!

Spec::Runner.configure do |config|

end
