class Mp4v2::Artwork
  def initialize(filename)
    @file = Pathname.new(filename).cleanpath
  end
end