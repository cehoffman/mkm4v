class MediaInfo::AudioTrack < MediaInfo::AbstractTrack
  attr_reader :codec, :duration, :bitrate, :channels, :samplerate, :size, :lang

  def initialize(source, track)
    super
    @codec = info 'Format'
    @duration = info('Duration').to_i # in milliseconds
    @bitrate = info('BitRate').to_i # in bits
    @channels = info('Channel(s)').to_i
    @samplerate = info('SamplingRate').to_i # in hertz
    @size = info('StreamSize').to_i # in bytes
    @lang = info('Language')
  end
end