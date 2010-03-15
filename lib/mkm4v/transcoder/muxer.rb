module Mkm4v::Transcoder::Muxer
  class SwapError < StandardError; end

  def initialize(info)
    @info = info
  end

  def swap(track)
    raise SwapError, "swaping tracks not support for container #{@info.container}"
  end

  def swap!(track, &processor)
    newfile = swap(track, &processor)
    File.move newfile, @info.file
    newfile
  end
end