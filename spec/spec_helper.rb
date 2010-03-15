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

module ConsoleHelpers
  def capture(&block)
    $stdout, $stderr = StringIO.new("", "r+"), StringIO.new("", "r+")

    yield

    $stdout.seek(0)
    $stderr.seek(0)

    stdout, stderr = $stdout, $stderr
    $stdout, $stderr = STDOUT, STDERR

    [stdout.read, stderr.read]
  end
end

Spec::Runner.configure do |config|
  config.include ConsoleHelpers
end
