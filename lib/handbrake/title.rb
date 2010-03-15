class Handbrake::Title
  attr_reader :id, :angles, :duration, :width, :height, :par, :dar, :fps,
              :chapters, :audio, :subtitles, :crop

  def initialize(title)
    puts title

    title = title.strip.split(/\n/)

    @id = title.shift[/title (\d+)/, 1].to_i

    # stream this is in
    title.shift

    @angles = title.shift[/angle\(s\) (\d+)/, 1].to_i
    @duration = Timestamp.new title.shift[/duration: ([\d:\.]+)/, 1]

    info = title.shift
    @width = info[/(\d+)x\d+/, 1].to_i
    @height = info[/\d+x(\d+)/, 1].to_i
    @par = $1.to_f / $2.to_f if info =~ /pixel aspect: (\d+)\/(\d+)/
    @dar = info[/display aspect: (\d+(?:\.\d+)?)/, 1].to_f
    @fps = info[/(\d+(?:\.\d+)) fps/, 1].to_f

    # autocrop settings
    @crop = {top: $1.to_i, right: $2.to_i, bottom: $3.to_i, left: $4.to_i} if title.shift =~ /(\d+)\/(\d+)\/(\d+)\/(\d+)/

    indent = title.first[/^(\s+)\+/, 1]

    @chapters, @audio, @subtitles = Handbrake::Chapters.new, [], []
    current = @chapters
    title.each do |line|
      case line
      when /\+ chapters:/
        current = :chapter
      when /\+ audio tracks:/
        current = :audio
      when /\+ subtitle tracks:/
        current = :subtitle
      when /^#{indent}\s+\+/ # only processes children of these branches
        case current
        when :chapter
          @chapters.push Timestamp.new(line[/duration ([\d:\.]+)/, 1]) + (@chapters.last || 0)
        when :audio
          @audio.push Handbrake::Audio.new line
        when :subtitle
          @subtitles.push Handbrake::Subtitle.new line
        end
      end
    end
  end
end
