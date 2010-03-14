class MediaInfo::ImageTrack
  include MediaInfo::Track

  property :resolution, 'Resolution', Integer
  property :width, 'Width', Integer
  property :height, 'Height', Integer
  property :size, 'StreamSize', Integer
  property :codec, 'Format'
  property :mime_type, 'InternetMediaType'
end