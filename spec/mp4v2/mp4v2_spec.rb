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

  specify "bool fields should only be true if value is set to true" do
    @mp4.gapless = "true"
    @mp4.should_not be_gapless
  end

  it "should raise error when setting string field with non string value" do
    @mp4.name = 2010
    -> { @mp4.save }.should raise_error(TypeError)
  end

  it "should raise error when setting a number field with a non number" do
    @mp4.episode = "4"
    -> { @mp4.save }.should raise_error(TypeError)
  end

  it "should raise error when setting bool field with non bool" do
    @mp4.podcast = "yes"
    -> { @mp4.save }.should raise_error(TypeError, "podcast is not a truth value or nil")
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
    it "should drop all fields that are not in file" do
      @mp4.should_not have_key(:album_artist)
      @mp4.album_artist = "Your Mom"
      @mp4.album_artist.should == "Your Mom"

      @mp4.reload!

      @mp4.should_not have_key(:album_artist)
      @mp4.album_artist.should == nil
    end
  end

  describe "#optimize!" do
    it "should return true if successful" do
      @mp4.optimize!.should == true
    end

    it "should replace file with optimized version" do
      pending # It does optimize but there is a little different every time
      @mp4.optimize!
      File.open(@mp4.file, "rb") do |modified|
        File.open(fixtures + "mp4v2.optimized.m4v", "rb") do |optimized|
          modified.read.should == optimized.read
        end
      end
    end
  end
end