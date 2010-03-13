require File.expand_path("../mediainfo/mediainfo", __FILE__)
require File.expand_path("../mediainfo/abstract", __FILE__)
require File.expand_path("../mediainfo/video", __FILE__)
require File.expand_path("../mediainfo/audio", __FILE__)
require File.expand_path("../mediainfo/menu", __FILE__)
require File.expand_path("../mediainfo/text", __FILE__)

class MediaInfo
  attr_reader :tracks
  attr_reader *TrackTypes

  def size
    info('FileSize').to_i # in bytes
  end

  def duration
    info('Duration').to_i # in milliseconds
  end

  def container
    info('Format')
  end

  def track_with_id(id)
    @tracks.select { |track| track.id == id}.pop
  end

  def info(query)
    track_info :general, 0, query
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
    audio.first.samplerate
  end

  def channels
    audio.first.channels
  end

  def audio_codec
    audio.first.codec
  end
end