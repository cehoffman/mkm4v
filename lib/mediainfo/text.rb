class MediaInfo::TextTrack < MediaInfo::AbstractTrack
  attr_reader :encoding, :lang

  def initialize(source, track)
    super
    @lang = info('Language')
    @encoding = Encoding.find(info('Format'))
  end
end