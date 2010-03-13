class MediaInfo::AbstractTrack
  def initialize(source, track)
    @source, @track, @track_type = source, track, self.class.to_s.split("::", 2).last.sub(/Track$/, '').downcase.to_sym
  end

  def id
    @id = info('ID').to_i
  end

  def info(query)
    @source.track_info @track_type, @track, query
  end
end