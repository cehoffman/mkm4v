class Mkm4v::Transcoder::Mkv
  include Mkm4v::Transcoder::Muxer

  def swap(track, &processor)
    rawtrack = Pathname.tmpfile @info.file, "raw"
    newfile = Pathname.tmpfile @info.file, "new"

    system %{mkvextract tracks "#{@info.file}" #{track.id}:"#{rawtrack}"}
    newtrack = yield rawtrack

    import = case track
             when MediaInfo::AudioTrack
               tracks = (@info.audio - [track])
               tracks.empty? && "-A" || %|--audio-tracks #{tracks.map(&:id).join(',')}|
             when MediaInfo::VideoTrack
               %|--video-tracks #{(@info.video - [track]).map(&:id).join(',')}|
             when MediaInfo::TextTrack
               %|--subtitle-tracks #{(@info.text - [track]).map(&:id).join(',')}|
             else
               raise SwapError, "don't know how to swap tracks of type #{track.class}"
             end

    order = @info.tracks.map(&:id).sort.map { |id| "0:#{id}" } - ["0:0"]
    order[track.id] = "1:0"
    lang = track.lang.empty? && "eng" || track.lang
    system %{mkvmerge -o "#{newfile}" --track-order #{order.join(',')} #{import} "#{@info.file}" --language 0:#{lang} "#{newtrack}"}
    File.delete rawtrack, newtrack

    newfile
  end
end