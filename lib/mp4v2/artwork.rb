class Mp4v2::Artwork
  attr_reader :format, :data

  def initialize(filename, data = nil)
    @file = Pathname.new(filename).cleanpath
    @data = data || @file.read
    @format = {"jpg" => :jpeg, "jpeg" => :jpeg, "bmp" => :bitmap, "png" => :png, "gif" => :gif}[filename[/\.([^\.]+)$/, 1]] || :unknown
  end

  def save
    @file.open("wb") { |f| f << @data }
  end

  def inspect
    "#<#{self.class} file=#{@file.basename.inspect} format=#{@format}>"
  end
end