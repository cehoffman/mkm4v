class MediaInfo::TextTrack
  include MediaInfo::Track

  property :encoding, 'Format', ->(raw) { Encoding.find(raw) }
  property :lang, 'Language'
end