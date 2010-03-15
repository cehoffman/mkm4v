class MediaInfo::GeneralTrack
  include MediaInfo::Track

  property :file, 'CompleteName', Pathname
  property :size, 'FileSize', Integer
  property :duration, 'Duration', Timestamp
  property :container, 'Format'
  property :mime_type, 'InternetMediaType'
  property :bitrate, 'OverallBitRate', Integer
  property :interleaved, 'Interleaved', Boolean
end