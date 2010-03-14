class MediaInfo::AudioTrack
  include MediaInfo::Track

  property :codec, 'Format'
  property :duration, 'Duration', Integer
  property :bitrate, 'BitRate', Integer
  property :channels, 'Channel(s)', Integer
  property :samplerate, 'SamplingRate', Integer
  property :size, 'StreamSize', Integer
  property :lang, 'Language'
end