require "open3"

class Handbrake
  attr_reader :stdout, :stderr, :title, :file
  Exe = `which HandBrakeCLI`.strip

  def initialize(filename)
    @file = Pathname.new(filename).expand_path

    stdin, stdout, stderr = Open3.popen3 %|#{Exe} -i "#{filename}" --title 0|
    stdout = stdout.read
    stderr = stderr.read

    @title = stderr.split(/^\+/)[1..-1].map &Title
  end

  def title?
    !@title.empty?
  end

private
end

require File.expand_path("../handbrake/title", __FILE__)
require File.expand_path("../handbrake/chapters", __FILE__)
require File.expand_path("../handbrake/audio", __FILE__)
require File.expand_path("../handbrake/subtitle", __FILE__)
