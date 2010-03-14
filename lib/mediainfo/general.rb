class MediaInfo::GeneralTrack
  include MediaInfo::Track

  property :file, 'CompleteName'
  property :size, 'FileSize', Integer
  property :duration, 'Duration', Integer
  property :container, 'Format'
end