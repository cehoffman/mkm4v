class Mp4v2::Artwork
  attr_reader :format

  def initialize(filename)
    @file = Pathname.new(filename).cleanpath
    @format = {"jpg" => :jpeg, "jpeg" => :jpeg, "bmp" => :bitmap, "png" => :png, "gif" => :gif}[filename[/\.([^\.]+)$/, 1]] || :unknown
  end
  
  def data
    @file.read
  end
end