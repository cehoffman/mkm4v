class MediaInfo::AudioTrack
  attr_reader :codec, :duration, :bitrate, :channels, :samplerate, :size

  def initialize(source, track)
    @codec = source.track_info :audio, track, 'Format'
    @duration = source.track_info(:audio, track, 'Duration').to_i # in milliseconds
    @bitrate = source.track_info(:audio, track, 'BitRate').to_i # in bits
    @channels = source.track_info(:audio, track, 'Channel(s)').to_i
    @samplerate = source.track_info(:audio, track, 'SamplingRate').to_i # in hertz
    @size = source.track_info(:audio, track, 'StreamSize').to_i # in bytes
  end
end