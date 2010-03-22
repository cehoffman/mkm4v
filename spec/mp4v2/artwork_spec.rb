require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Mp4v2::Artwork do
  before(:all) do
    @file = fixtures + "mp4v2.m4v"
    @orig1 = fixtures + "artwork01.jpg"
    @orig2 = fixtures + "artwork02.jpg"

    @art1 = Mp4v2::Artwork.new @orig1
    @art2 = Mp4v2::Artwork.new @orig2
  end

  before(:each) do
    FileUtils.cp @file, @file.extname("test")
    @mp4 = Mp4v2.new @file.extname("test")
  end

  after(:all) do
    FileUtils.rm @file.extname("test")
  end

  describe "#file" do
    it "from standalone image should have a file accessor pointing to where file came from" do
      @art1.file.should == @orig1
      @art2.file.should == @orig2
    end

    it "from mp4 file should have a file accessor pointing to where file would be saved" do
      @mp4.artwork[0].file.should =~ /^#{Regexp.escape(fixtures + "mp4v2.01.jpg")}$/
      @mp4.artwork[1].file.should =~ /^#{Regexp.escape(fixtures + "mp4v2.02.jpg")}$/
    end
  end

  describe "#format" do
    describe "from standalone image" do
      include FakeFS::SpecHelpers

      it "should set format to :jpeg for a .jpeg file" do
        FileUtils.touch "artwork.jpeg"

        Mp4v2::Artwork.new("artwork.jpeg").format.should == :jpeg
      end

      it "should set format to :jpeg for a .jpg file" do
        FileUtils.touch "artwork.jpg"

        Mp4v2::Artwork.new("artwork.jpg").format.should == :jpeg
      end

      it "should set format to :bitmap for a .bmp file" do
        FileUtils.touch "artwork.bmp"

        Mp4v2::Artwork.new("artwork.bmp").format.should == :bitmap
      end

      it "should set format to :gif for a .gif file" do
        FileUtils.touch "artwork.gif"

        Mp4v2::Artwork.new("artwork.gif").format.should == :gif
      end

      it "should set format to :png for a .png file" do
        FileUtils.touch "artwork.png"

        Mp4v2::Artwork.new("artwork.png").format.should == :png
      end

      it "should set format to :unknown for an unknown extension" do
        FileUtils.touch "artwork.eps"

        Mp4v2::Artwork.new("artwork.eps").format.should == :unknown
      end
    end

    describe "from mp4 file" do
      include FakeFS::SpecHelpers

      it "should set format to :jpeg for a .jpeg file" do
        File.open("artwork.jpeg", "w") { |f| f << "Data" }

        @mp4.artwork << Mp4v2::Artwork.new("artwork.jpeg")
        @mp4.save reload: true

        @mp4.artwork[2].format.should == :jpeg
      end

      it "should set format to :jpeg for a .jpg file" do
        File.open("artwork.jpg", "w") { |f| f << "Data" }

        @mp4.artwork << Mp4v2::Artwork.new("artwork.jpg")
        @mp4.save reload: true

        @mp4.artwork[2].format.should == :jpeg
      end

      it "should set format to :bitmap for a .bmp file" do
        File.open("artwork.bmp", "w") { |f| f << "Data" }

        @mp4.artwork << Mp4v2::Artwork.new("artwork.bmp")
        @mp4.save reload: true

        @mp4.artwork[2].format.should == :bitmap
      end

      it "should set format to :gif for a .gif file" do
        File.open("artwork.gif", "w") { |f| f << "Data" }

        @mp4.artwork << Mp4v2::Artwork.new("artwork.gif")
        @mp4.save reload: true

        @mp4.artwork[2].format.should == :gif
      end

      it "should set format to :png for a .png file" do
        File.open("artwork.png", "w") { |f| f << "Data" }

        @mp4.artwork << Mp4v2::Artwork.new("artwork.png")
        @mp4.save reload: true

        @mp4.artwork[2].format.should == :png
      end

      it "should set format to :unknown for an unknown extension" do
        File.open("artwork.eps", "w") { |f| f << "Data" }

        @mp4.artwork << Mp4v2::Artwork.new("artwork.eps")
        @mp4.save reload: true

        @mp4.artwork[2].format.should == :unknown
      end
    end
  end

  describe "#data" do
    it "from standalone image should equal the contents of image file" do
      @art1.data.should == File.open(@orig1, "rb") { |f| f.read }
      @art2.data.should == File.open(@orig2, "rb") { |f| f.read }
    end

    it "from mp4 file should equal the contents of image file" do
      @mp4.artwork[0].data.should == File.open(@orig1, "rb") { |f| f.read }
      @mp4.artwork[1].data.should == File.open(@orig2, "rb") { |f| f.read }
    end
  end

  describe "#save" do
    it "from standalone image should write data contents to file location" do
      FakeFS.activate!
      File.open("artwork.png", "w") { |f| f << "Data" }

      art = Mp4v2::Artwork.new("artwork.png")

      File.delete("artwork.png")

      art.save

      File.read("artwork.png").should == "Data"
      FakeFS.deactivate!
    end

    it "from mp4 file should write data contents to file location" do
      @mp4.artwork[0].save

      saved = File.open(@mp4.artwork[0].file, "rb") { |f| f.read }

      saved.should == @mp4.artwork[0].data

      File.delete(@mp4.artwork[0].file)
    end
  end

  specify "two artwork should be equal if data are equal" do
    FakeFS.activate!
    File.open("artwork1.jpeg", "w") { |f| f << "Be Equal" }
    File.open("artwork2.png", "w") { |f| f << "Be Equal" }
    File.open("artwork3.jpeg", "w") { |f| f << "Not Equal" }

    Mp4v2::Artwork.new("artwork1.jpeg").should == Mp4v2::Artwork.new("artwork2.png")
    Mp4v2::Artwork.new("artwork1.jpeg").should_not == Mp4v2::Artwork.new("artwork3.jpeg")
    FakeFS.deactivate!
  end

  specify "#inspect should show the class name, file basename, and format" do
    @art1.inspect.should == "#<Mp4v2::Artwork file=artwork01.jpg format=jpeg>"

    @art1.should_receive(:class)
    @art1.file.should_receive(:basename)

    @art1.inspect
  end
end