class MediaInfo::VideoTrack
  attr_reader :duration, :width, :height, :dar, :par, :fps, :region, :lang, :codec

  def initialize(source, track)
    @duration = source.track_info :video, track, "Duration"
    @width = source.track_info(:video, track, 'Width').to_i
    @height = source.track_info(:video, track, 'Height').to_i
    @dar = source.track_info(:video, track, 'DisplayAspectRatio').to_f
    @par = source.track_info(:video, track, 'PixelAspectRatio').to_f
    @fps = source.track_info(:video, track, 'FrameRate').to_f
    @region = source.track_info(:video, track, 'Standard') # NTSC or PAL
    @interlaced = source.track_info(:video, track, 'ScanType') == "Interlaced" # Interlaced or Progressive
    #'StreamSize'
    @lang = source.track_info :video, track, 'Language'
    @codec = source.track_info :video, track, 'Format'
  end

  def interlaced?
    @interlaced
  end
end