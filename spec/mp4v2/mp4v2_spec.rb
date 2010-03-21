require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Mp4v2 do
  before(:all) do
    @file = fixtures + "mp4v2.m4v"
  end

  before(:each) do
    FileUtils.cp @file, @file.extname("test")
    @mp4 = Mp4v2.new @file.extname("test")
  end

  after(:all) do
    FileUtils.rm @file.extname("test")
  end

  it "should have access to metadata through keys" do
    @mp4.should have_key(:hd)
    @mp4[:hd].should == false
  end

  it "should have methods to access keys" do
    @mp4.should respond_to(:hd)
    @mp4.hd.should == false
  end

  it "should set corresponding keys when setting properties from methods" do
    @mp4.should_not have_key(:album_artist)
    @mp4.album_artist = "Your Mom"
    @mp4.should have_key(:album_artist)
  end

  it "should return nil for properties that are not set" do
    @mp4.album_artist.should == nil
  end

  it "should know the file it opened" do
    @mp4.file.should =~ /\/mp4v2\.test$/
  end

  def self.metadata(meta, value, &block)
    specify "#{meta} should be gettable, settable, and clearable" do
      @mp4[meta] = value
      @mp4.save reload: true
      @mp4[meta].should == value
      @mp4[meta] = nil
      @mp4.save reload: true
      @mp4.should_not have_key(meta)
    end
  end

  metadata :name, "A Name"
  metadata :artist, "Some Artist"
  metadata :album_artist, "Album Artist"
  metadata :album, "Album"
  metadata :grouping, "Grouping"
  metadata :composer, "Composer"
  metadata :comments, "Comments"
  metadata :genre, "Genre"
  metadata :genre_type, 2**16 - 1
  metadata :released, DateTime.civil(2004, 11, 16, 6)
  metadata :track, 2**16 - 1
  metadata :tracks, 2**16 - 1
  metadata :disk, 2**16 - 1
  metadata :disks, 2**16 - 1
  metadata :tempo, 2**16 - 1
  metadata :show, "Show"
  metadata :episode_id, "ID"
  metadata :season, 2**32 - 1
  metadata :episode, 2**32 - 1
  metadata :network, "Network"
  metadata :description, "A Description"
  metadata :long_description, "A Long description"
  metadata :lyrics, "Lyrics"
  metadata :copyright, "Copyright"
  metadata :encoding_tool, "HandBrake"
  metadata :encoded_by, "Me"
  metadata :category, "Category"

  # media type is a set of possible symbols
  metadata :kind, :music
  metadata :kind, :audiobook
  metadata :kind, :music_video
  metadata :kind, :movie
  metadata :kind, :tv
  metadata :kind, :booklet
  metadata :kind, :ringtone

  specify "kind should not be sent when invalid" do
    @mp4.kind = :invalid
    @mp4.save reload: true
    @mp4.should_not have_key(:kind)
  end

  # content rating is a set of possible symbols
  metadata :advisory, :none
  metadata :advisory, :clean
  metadata :advisory, :explicit

  specify "advisory warning should not be set when invalid" do
    @mp4.advisory = :invalid
    @mp4.save reload: true
    @mp4.should_not have_key(:invalid)
  end

  metadata :purchased, DateTime.civil(2009, 12, 1)
  metadata :account, "iTunes account"
  metadata :account_type, 255
  metadata :country, 2*32 - 1
  metadata :cnID, 2**32 - 1
  metadata :atID, 2**32 - 1
  metadata :plID, 2**64 - 1
  metadata :geID, 2**32 - 1

  specify "compilation should have a boolean accessor" do
    @mp4.should_not be_compilation
    @mp4.compilation = true
    @mp4.save reload: true
    @mp4.should be_compilation
  end

  specify "podcast should have a boolean accessor" do
    @mp4.should_not be_podcast
    @mp4.podcast = true
    @mp4.save reload: true
    @mp4.should be_podcast
  end

  specify "hd should have a boolean accessor" do
    @mp4.should_not be_hd
    @mp4.hd = true
    @mp4.save reload: true
    @mp4.should be_hd
  end

  specify "gapless should have a boolen accessor" do
    @mp4.should_not be_gapless
    @mp4.gapless = true
    @mp4.save reload: true
    @mp4.should be_gapless
  end

  describe "string fields" do
    it "should coerce to string when given non string value" do
      @mp4.name = 2010

      -> { @mp4.save reload: true }.should_not raise_error

      @mp4.name.should == "2010"
    end

    it "should call to_str before to_s to coerce to string" do
      class NonString
        def to_str
          "My Value"
        end

        def to_s
        end
      end

      field = NonString.new
      field.should_not_receive(:to_s)

      @mp4.name = field
      -> { @mp4.save reload: true }.should_not raise_error
      @mp4.name.should == "My Value"
    end

    it "should raise a helpful TypeError when it can't be coerced" do
      class Unconvertable
        def to_str
          234 # Not a string is the important part
        end
      end

      @mp4.name = Unconvertable.new
      -> { @mp4.save }.should raise_error(TypeError, "can't convert name to string")

      class Unconvertable
        undef to_str, to_s
      end

      @mp4.name = nil
      @mp4.comments = Unconvertable.new
      -> { @mp4.save }.should raise_error(TypeError, "can't convert comments to string")
    end
  end

  describe "numeric fields" do
    it "should coerce to integer when given non integer" do
      @mp4.cnID = "10001"

      -> { @mp4.save reload: true }.should_not raise_error

      @mp4.cnID.should == 10001
    end

    it "should raise error when setting number above max range of field" do
      @mp4.cnID = 2**32

      -> { @mp4.save }.should raise_error(RangeError, "cnID max value is #{2**32 - 1}")
    end

    it "should call to_int before to_i to coerce to integer" do
      class NonFixnum
        def to_int
          2300
        end

        def to_i; end
      end

      field = NonFixnum.new
      field.should_not_receive(:to_i)
      @mp4.cnID = field

      -> { @mp4.save reload: true }.should_not raise_error

      @mp4.cnID.should == 2300
    end

    it "should raise a helpful TypeError when it can't be coerced" do
      class Unconvertable
        def to_int
          "Not an integer"
        end
      end

      @mp4.cnID = Unconvertable.new

      -> { @mp4.save }.should raise_error(TypeError, "can't convert cnID to integer")

      class Unconvertable
        undef to_int
      end

      @mp4.cnID = Unconvertable.new

      -> { @mp4.save }.should raise_error(TypeError, "can't convert cnID to integer")
    end
  end

  describe "boolean fields" do
    it "should use ruby's truth system" do
      @mp4.gapless = "Will be true"
      @mp4.should be_gapless

      -> { @mp4.save reload: true }.should_not raise_error

      @mp4.gapless.should == true
    end
  end

  describe "date fields" do
    it "should coerce strings to datetime" do
      @mp4.released = "2004-11-27T04:00:01Z"

      -> { @mp4.save reload: true }.should_not raise_error

      @mp4.released.should == DateTime.civil(2004, 11, 27, 4, 0, 1)
    end

    it "should raise an error when unable to parse string" do
      @mp4.released = "Some garbage"

      -> { @mp4.save }.should raise_error(TypeError, "can't convert released to DateTime")
    end
  end

  describe "#save" do
    it "should accept a hash of options" do
      @mp4.save option: "Value"
    end

    it "it should return itself after save" do
      @mp4.save.__id__.should == @mp4.__id__
    end

    it "should take an option to reload the file" do
      @mp4.should_receive(:reload!).once
      @mp4.save reload: true
    end

    it "should not reload by default" do
      @mp4.should_not_receive(:reload!)
      @mp4.save
    end

    it "should take an option to optimize the file" do
      @mp4.should_receive(:optimize!).once
      @mp4.save optimize: true
    end

    it "should not optimize by default" do
      @mp4.should_not_receive(:optimize!)
      @mp4.save
    end

    it "should optimize and then reload when both options given" do
      @mp4.should_receive(:optimize!).ordered
      @mp4.should_receive(:reload!).ordered

      @mp4.save optimize: true, reload: true
    end
  end

  describe "#reload!" do
    it "should reread properties of file" do
      @mp4.video.clear
      @mp4.audio.clear
      @mp4.should_receive(:clear).once

      @mp4.reload!

      @mp4.video.should_not be_empty
      @mp4.audio.should_not be_empty
    end
  end

  describe "#clear" do
    it "should drop all metadata fields" do
      audio, video, text, chapters, file = @mp4.audio, @mp4.video, @mp4.text, @mp4.chapters, @mp4.file

      @mp4.name = "Filled"
      @mp4.artist = "Filled"
      @mp4.album_artist = "Filled"
      @mp4.album = "Filled"
      @mp4.grouping = "Filled"
      @mp4.composer = "Filled"
      @mp4.comments = "Filled"
      @mp4.genre = "Filled"
      @mp4.genre_type = 1
      @mp4.released = DateTime.civil(2004, 3, 10)
      @mp4.track = 1
      @mp4.tracks = 10
      @mp4.disk = 1
      @mp4.disks = 2
      @mp4.tempo = 50
      @mp4.show = "Filled"
      @mp4.episode_id = "Filled"
      @mp4.season = 1
      @mp4.episode = 1
      @mp4.network = "Filled"
      @mp4.description = "Filled"
      @mp4.long_description = "Filled"
      @mp4.lyrics = "Filled"
      @mp4.copyright = "Filled"
      @mp4.encoding_tool = "Filled"
      @mp4.encoded_by = "Filled"
      @mp4.category = "Filled"
      @mp4.kind = :movie
      @mp4.advisory = :clean
      @mp4.purchased = DateTime.civil(2009, 12, 1)
      @mp4.account = "Filled"
      @mp4.account_type = 255
      @mp4.country = 1
      @mp4.cnID = 1
      @mp4.atID = 1
      @mp4.plID = 1
      @mp4.geID = 1

      @mp4.gapless = true
      @mp4.compilation = true
      @mp4.podcast = true
      @mp4.hd = true

      @mp4.clear

      # Check that it didn't remove non metadata fields
      @mp4.audio.should == audio
      @mp4.video.should == video
      @mp4.text.should == text
      @mp4.chapters.should == chapters
      @mp4.file.should == file

      # Check that all metadata fields will be cleared
      @mp4.name.should be_nil
      @mp4.artist.should be_nil
      @mp4.album_artist.should be_nil
      @mp4.album.should be_nil
      @mp4.grouping.should be_nil
      @mp4.composer.should be_nil
      @mp4.comments.should be_nil
      @mp4.genre.should be_nil
      @mp4.genre_type.should be_nil
      @mp4.released.should be_nil
      @mp4.track.should be_nil
      @mp4.tracks.should be_nil
      @mp4.disk.should be_nil
      @mp4.disks.should be_nil
      @mp4.tempo.should be_nil
      @mp4.show.should be_nil
      @mp4.episode_id.should be_nil
      @mp4.season.should be_nil
      @mp4.episode.should be_nil
      @mp4.network.should be_nil
      @mp4.description.should be_nil
      @mp4.long_description.should be_nil
      @mp4.lyrics.should be_nil
      @mp4.copyright.should be_nil
      @mp4.encoding_tool.should be_nil
      @mp4.encoded_by.should be_nil
      @mp4.category.should be_nil
      @mp4.kind.should be_nil
      @mp4.purchased.should be_nil
      @mp4.account.should be_nil
      @mp4.account_type.should be_nil
      @mp4.country.should be_nil
      @mp4.cnID.should be_nil
      @mp4.atID.should be_nil
      @mp4.plID.should be_nil
      @mp4.geID.should be_nil

      @mp4.advisory.should be_nil
      @mp4.gapless.should be_false
      @mp4.compilation.should be_false
      @mp4.podcast.should be_false
      @mp4.hd.should be_false

      @mp4.keys.sort.should == [:audio, :chapters, :file, :text, :video]
    end
  end

  describe "#clear!" do
    it "should drop all metadata fields and save the file" do
      @mp4.should_receive(:clear).once.ordered
      @mp4.should_receive(:save).once.ordered
      @mp4.clear!
    end
  end

  describe "#optimize!" do
    it "should return true if successful" do
      @mp4.optimize!.should == true
    end

    it "should replace file with optimized version" do
      pending # It does optimize but there is a little difference every time
      @mp4.optimize!
      File.open(@mp4.file, "rb") do |modified|
        File.open(fixtures + "mp4v2.optimized.m4v", "rb") do |optimized|
          modified.read.should == optimized.read
        end
      end
    end
  end
end