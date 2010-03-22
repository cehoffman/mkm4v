require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
%w(boolean date generic numeric symbol string).each do |shared|
  require File.expand_path("../shared/#{shared}.rb", __FILE__)
end

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

  describe "metadata access" do
    before(:each) do
      @mp4[:hd] = true
      @mp4.save reload: true
    end

    it "should have access through keys" do
      @mp4.should have_key(:hd)
      @mp4[:hd].should == true
    end

    it "should have access thorugh methods" do
      @mp4.should respond_to(:hd)
      @mp4.hd.should == true
    end

    it "should set corresponding keys when setting properties from methods" do
      @mp4.should_not have_key(:album_artist)
      @mp4.album_artist = "Your Mom"
      @mp4.should have_key(:album_artist)
    end

    it "should return nil for properties that are not set" do
      @mp4.album_artist.should == nil
    end
  end

  it "should know the file it opened" do
    @mp4.file.should =~ /\/mp4v2\.test$/
  end

  def self.metadata(type, field, *values)
    values.flatten!
    values.compact!
    mappings = values.last.is_a?(Hash) ? values.pop : {}

    values.each { |val| mappings[val] = val }

    describe field do
      define_method :field do
          field
      end

      mappings.each_pair do |set, get|
        @@setter = set
        define_method :setter do
          set
        end

        @@getter = get
        define_method :getter do
          get
        end

        it_should_behave_like "generic metadata field"
      end

      it "should be clearable" do
        @mp4[field] = setter
        @mp4.save reload: true
        @mp4.should have_key(field)
        @mp4[field] = nil
        @mp4.save reload: true
        @mp4.should_not have_key(field)
      end

      it_should_behave_like "#{type} metadata field"
    end
  end

  metadata :string, :name, "A Name"
  metadata :string, :artist, "Some Artist"
  metadata :string, :album_artist, "Album Artist"
  metadata :string, :album, "Album"
  metadata :string, :grouping, "Grouping"
  metadata :string, :composer, "Composer"
  metadata :string, :comments, "Comments"
  metadata :string, :genre, "Genre"
  metadata :numeric, :genre_type, 2**16 - 1
  metadata :date, :released, DateTime.civil(2004, 11, 16, 6), "2004/11/16" => DateTime.civil(2004, 11, 16)
  metadata :numeric, :track, 2**16 - 1, "1" => 1
  metadata :numeric, :tracks, 2**16 - 1, "10" => 10

  specify "setting only track should not set tracks after save" do
    @mp4.track = 1

    @mp4.save reload: true

    @mp4.should_not have_key(:tracks)
  end

  specify "setting only tracks should not set track after save" do
    @mp4.tracks = 1

    @mp4.save reload: true

    @mp4.should_not have_key(:track)
  end

  metadata :numeric, :disk, 2**16 - 1, "1" => 1
  metadata :numeric, :disks, 2**16 - 1, "2" => 2

  specify "setting only disk should not set disks after save" do
    @mp4.disk = 1

    @mp4.save reload: true

    @mp4.should_not have_key(:disks)
  end

  specify "setting only disks should not set disk after save" do
    @mp4.disks = 1

    @mp4.save reload: true

    @mp4.should_not have_key(:disk)
  end

  metadata :numeric, :tempo, 2**16 - 1, "50" => 50
  metadata :string, :show, "Show"
  metadata :string, :episode_id, "ID"
  metadata :numeric, :season, 2**32 - 1, "1" => 1
  metadata :numeric, :episode, 2**32 - 1, "1" => 1
  metadata :string, :network, "Network"
  metadata :string, :description, "A Description"
  metadata :string, :long_description, "A Long description"
  metadata :string, :lyrics, "Lyrics"
  metadata :string, :copyright, "Copyright"
  metadata :string, :encoding_tool, "HandBrake"
  metadata :string, :encoded_by, "Me"
  metadata :string, :category, "Category"

  metadata :symbol, :kind, :music, :audiobook, :music_video, :movie, :tv, :booklet, :ringtone

  metadata :symbol, :advisory, :none, :clean, :explicit

  metadata :date, :purchased, DateTime.civil(2009, 12, 1), "2009-12-1" => DateTime.civil(2009, 12, 1)
  metadata :string, :account, "iTunes account"
  metadata :numeric, :account_type, 255, "1" => 1
  metadata :numeric, :country, 2*32 - 1, "1" => 1
  metadata :numeric, :cnID, 2**32 - 1, "1" => 1
  metadata :numeric, :atID, 2**32 - 1, "1" => 1
  metadata :numeric, :plID, 2**64 - 1, "1" => 1
  metadata :numeric, :geID, 2**32 - 1, "1" => 1

  metadata :boolean, :compilation, true, false, "Truth Value" => true
  metadata :boolean, :podcast, true, false, "Truth Value" => true
  metadata :boolean, :hd, true, false, "Truth Value" => true
  metadata :boolean, :gapless, true, false, "Truth Value" => true

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

    # A little bit of a hack to test that it just makes a different file
    # but the whole optimize part is out of my hands anyway so should
    # be sufficient
    require "digest/md5"
    it "should replace file with optimized version" do
      digest = Digest::MD5.hexdigest File.read(@mp4.file)

      @mp4.optimize!

      digest.should_not == Digest::MD5.hexdigest(File.read(@mp4.file))
    end
  end
end