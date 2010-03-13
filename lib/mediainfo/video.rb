class MediaInfo::VideoTrack < MediaInfo::AbstractTrack
  attr_reader :duration, :width, :height, :dar, :par, :fps, :region, :size, :lang, :codec

  def initialize(source, track)
    super
    @duration = info("Duration").to_i # in milliseconds
    @width = info('Width').to_i # in pixels
    @height = info('Height').to_i # in pixels
    @dar = info('DisplayAspectRatio').to_f
    @par = info('PixelAspectRatio').to_f
    @fps = info('FrameRate').to_f
    @region = info('Standard') # NTSC or PAL
    @interlaced = info('ScanType') == "Interlaced" # Interlaced or Progressive
    @size = info('StreamSize').to_i # in bytes
    @lang = info 'Language'
    @codec = info 'Format'
  end

  def interlaced?
    @interlaced
  end

  def ntsc?
    @standard == "NTSC"
  end

  def pal?
    @standard == "PAL"
  end
end