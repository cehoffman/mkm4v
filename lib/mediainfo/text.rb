class MediaInfo::TextTrack
  include MediaInfo::Track

  property :encoding, 'Format', Encoding
  property :lang, 'Language'
end