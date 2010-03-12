require File.expand_path("../mediainfo/mediainfo", __FILE__)
require File.expand_path("../mediainfo/video", __FILE__)
require File.expand_path("../mediainfo/audio", __FILE__)

class MediaInfo
  attr_reader :tracks

  def [](key)
    @tracks[key.to_sym]
  end

  def height
    self[:video].first.height
  end

  def width
    self[:video].first.width
  end

  def dar
    self[:video].first.dar
  end

  def par
    self[:video].first.par
  end
end