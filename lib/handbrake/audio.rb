class Handbrake::Audio
  attr_reader :id, :codec, :lang, :samplerate, :bitrate, :channels

  def initialize(audio)
    @id = audio[/\+ (\d+),/, 1].to_i
    @codec = audio[/\(([\w\d-]+)\)/, 1]
    @channels = $1.to_i + $2.to_i if audio =~ /\((\d+)\.(\d+) ch\)/
    @lang = audio[/\(iso639-2: (\w+)\)/, 1]
    @samplerate = $1.to_i if audio =~ /(\d+)Hz/
    @bitrate = $1.to_i if audio =~ /(\d+)bps/
  end
end