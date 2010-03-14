class MediaInfo::GeneralTrack
  include MediaInfo::Track

  property :file, 'CompleteName', Pathname
  property :size, 'FileSize', Integer
  property :duration, 'Duration', Integer
  property :container, 'Format'
  property :mime_type, 'InternetMediaType'
  property :size, 'FileSize', Integer
  property :duration, 'Duration', Integer
  property :bitrate, 'OverallBitRate_Mode', Integer
  property :interleaved, 'Interleaved', Boolean
end