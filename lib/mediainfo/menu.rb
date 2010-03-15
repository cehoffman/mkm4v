class MediaInfo::MenuTrack
  include MediaInfo::Track

  attr_reader :chapters

  initialized do
    @chapters = []
    start, stop = info('Chapters_Pos_Begin').to_i, info('Chapters_Pos_End').to_i
    (start...stop).each { |i| @chapters.push ::Timestamp.new(info(i, :name)) }
  end
end
