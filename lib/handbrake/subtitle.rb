class Handbrake::Subtitle
  attr_reader :id, :lang

  def initialize(subtitle)
    @id = subtitle[/\+ (\d+)/, 1].to_i
    @lang = subtitle[/\(iso639-2: (\w+)\)/, 1]
  end
end