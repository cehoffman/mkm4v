require 'bundler/setup'
$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require "mkm4v"
# require "ruby-debug"
require "fileutils"
require "fakefs/safe"
require "fakefs/spec_helpers"

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

RSpec.configure do |config|
  config.include ConsoleHelpers

  def fixtures
    Pathname.new(__FILE__).dirname + "fixtures"
  end
end
