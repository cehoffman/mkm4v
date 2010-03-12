require File.expand_path("../mediainfo/mediainfo", __FILE__)
require File.expand_path("../mediainfo/video", __FILE__)
require File.expand_path("../mediainfo/audio", __FILE__)

class MediaInfo
  attr_reader :tracks
  attr_reader *TrackTypes

  def [](key)
    @tracks[key.to_sym]
  end

  def size
    track_info(:general, 0, 'FileSize').to_i # in bytes
  end

  def duration
    track_info(:general, 0, 'Duration').to_i # in seconds
  end

  def height
    video.first.height
  end

  def width
    video.first.width
  end

  def dar
    video.first.dar
  end

  def par
    video.first.par
  end

  def video_codec
    video.first.codec
  end

  def samplerate
    audio.firat.samplerate
  end

  def bitrate
    audio.first.samplerate
  end

  def channels
    audio.first.channels
  end

  def audio_codec
    audio.first.codec
  end
end