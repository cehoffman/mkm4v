class MediaInfo::VideoTrack
  include MediaInfo::Track

  property :duration, 'Duration', Integer
  property :width, 'Width', Integer
  property :height, 'Height', Integer
  property :dar, 'DisplayAspectRatio', Float
  property :par, 'PixelAspectRatio', Float
  property :fps, 'FrameRate', Float
  property :region, 'Standard'
  property :size, 'StreamSize', Integer
  property :lang, 'Language'
  property :codec, 'Format'

  def interlaced?
    region == "Interlaced"
  end

  def ntsc?
    @standard == "NTSC"
  end

  def pal?
    @standard == "PAL"
  end
end