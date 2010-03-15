class MediaInfo::VideoTrack
  include MediaInfo::Track

  property :duration, 'Duration', Timestamp
  property :width, 'Width', Integer
  property :height, 'Height', Integer
  property :dar, 'DisplayAspectRatio', Float
  property :par, 'PixelAspectRatio', Float
  property :fps, 'FrameRate', Float
  property :region, 'Standard'
  property :interlaced, 'Standard', Boolean("Interlaced")
  property :ntsc, 'Standard', Boolean("NTSC")
  property :pal, 'Standard', Boolean("PAL")
  property :size, 'StreamSize', Integer
  property :lang, 'Language'
  property :codec, 'Format'
  property :frames, 'FrameCount', Integer
end