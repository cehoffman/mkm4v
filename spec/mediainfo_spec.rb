require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe MediaInfo do
  before(:all) do
    @mediainfo = MediaInfo.new(File.expand_path("../fixtures/sample_mpeg4.mp4", __FILE__))
    @system_newline = $/.dup
  end

  # Avoid side effects from failing tests on newlines
  after(:each) do
    $/ = @system_newline
  end

  it "should save the path to the opened file in utf-8" do
    @mediainfo.file.should == File.expand_path("../fixtures/sample_mpeg4.mp4", __FILE__)
    @mediainfo.file.encoding.should == Encoding::UTF_8
  end

  it "should provide access to all the track types" do
    MediaInfo::TrackTypes.each { |type| @mediainfo.send(type).should be_an_instance_of(Array) }
  end

  it "should have an array of video tracks" do
    @mediainfo.video.all? { |t| t.should be_an_instance_of(MediaInfo::VideoTrack) }
    @mediainfo.video.count.should == 1
  end

  it "should have an array of audio tracks" do
    @mediainfo.audio.all? { |t| t.should be_an_instance_of(MediaInfo::AudioTrack) }
    @mediainfo.audio.count.should == 1
  end

  it "should dynamically create new track types depending on environment" do
    @mediainfo.instance_variable_get(:@bogus).should be_nil

    class ::MediaInfo::BogusTrack; end
    MediaInfo::TrackTypes << :bogus
    mediainfo = MediaInfo.new(File.expand_path("../fixtures/sample_mpeg4.mp4", __FILE__))

    mediainfo.instance_variable_get(:@bogus).should be_an_instance_of(Array)

    MediaInfo::TrackTypes.delete :bogus
    MediaInfo.send :remove_const, :BogusTrack
  end

  describe "#track_info" do
    it "should complain if the stream type is not valid" do
      lambda { @mediainfo.track_info nil, 0, 'Duration'}.should raise_error(ArgumentError)
      lambda { @mediainfo.track_info :bogus, 0, 'Duration'}.should raise_error(ArgumentError)
      lambda { @mediainfo.track_info [], 0, 'Duration'}.should raise_error(ArgumentError)
    end

    it "should return info for a track" do
      @mediainfo.track_info(:video, 0, 'Height').should == "240"
    end

    it "should return strings in utf-8" do
      @mediainfo.track_info(:video, 0, 'Height').encoding.should == Encoding::UTF_8
    end
  end

  describe "#options" do
    it "should work the class for global option setting" do
      MediaInfo.options "Internet" => "No"
      pending { MediaInfo.options("Internet")["Internet"].should == "1" }
    end

    it "should work on an instance for instance specific options" do
      @mediainfo.options "Internet" => "No"
      pending { @mediainfo.options("Internet")["Internet"].should == "1" }
    end

    it "should replace \\r with system newline terminators" do
      @mediainfo.options("Info_Codecs")["Info_Codecs"].should =~ /;3COM NBX;2CC;A;;;3Com Corporation\n;FAAD AAC;2CC;A\n/
      $/ = "\r\n"
      @mediainfo.options("Info_Codecs")["Info_Codecs"].should =~ /;3COM NBX;2CC;A;;;3Com Corporation\r\n;FAAD AAC;2CC;A\r\n/
    end

    it "should return option strings in utf-8" do
      @mediainfo.options("Info_Version")["Info_Version"].encoding.should == Encoding::UTF_8
    end
  end

  it "should output information in xml" do
    @mediainfo.to_xml.gsub($/, "\n").should == File.read(File.expand_path("../fixtures/sample_mpeg4.xml", __FILE__))
  end

  it "should output information in xml using system newlines" do
    $/ = "\r\n"
    @mediainfo.to_xml.should == File.read(File.expand_path("../fixtures/sample_mpeg4.xml", __FILE__)).gsub("\n", "\r\n")
  end

  it "should output information in html" do
    @mediainfo.to_html.gsub($/, "\n").should == File.read(File.expand_path("../fixtures/sample_mpeg4.html", __FILE__))
  end

  it "should output information in html using system newlines" do
    $/ = "\r\n"
    @mediainfo.to_html.should == File.read(File.expand_path("../fixtures/sample_mpeg4.html", __FILE__)).gsub("\n", "\r\n")
  end

  it "should output information in a human readable format" do
    @mediainfo.to_s.gsub($/, "\n").should == File.read(File.expand_path("../fixtures/sample_mpeg4.txt", __FILE__))
  end

  it "should output information in a human readable format using system newlines" do
    $/ = "\r\n"
    @mediainfo.to_s.should == File.read(File.expand_path("../fixtures/sample_mpeg4.txt", __FILE__)).gsub("\n", "\r\n")
  end

  it "should return information forms in utf-8" do
    warn "Test needs to be run in a non UTF-8 encoding to test. Try LANG=en_US.ASCII-7BIT rake spec" if __ENCODING__ == Encoding::UTF_8
    [@mediainfo.to_s, @mediainfo.to_xml, @mediainfo.to_html].each { |info| info.encoding.should == Encoding::UTF_8 }
  end

  it "should not use rb_str_new or rb_str_new2 because of encoding" do
    File.read(File.expand_path("../../ext/mediainfo/mediainfo.c", __FILE__)).should_not include("rb_str_new")
  end

  it "should provide a shortcut to video properties" do
    @mediainfo.height.should == @mediainfo.video.first.height
    @mediainfo.width.should == @mediainfo.video.first.width
    @mediainfo.dar.should == @mediainfo.video.first.dar
    @mediainfo.par.should == @mediainfo.video.first.par
    @mediainfo.video_codec.should == @mediainfo.video.first.codec
  end

  it "should provide a shortcut to audio properties" do
    @mediainfo.samplerate.should == @mediainfo.audio.first.samplerate
    @mediainfo.audio_codec.should == @mediainfo.audio.first.codec
    @mediainfo.channels.should == @mediainfo.audio.first.channels
  end

  it "should know the file duration" do
    @mediainfo.duration.should == 4992
  end

  it "should know the file size" do
    @mediainfo.size.should == 245779
  end

  it "should know how many tracks there are in total" do
    @mediainfo.tracks.count.should == 2
  end

  describe MediaInfo::VideoTrack do
    before(:all) do
      @video = @mediainfo.video.first
    end

    it "should know the height" do
      @video.height.should == 240
    end

    it "should know the width" do
      @video.width.should == 190
    end

    it "should know the duration" do
      @video.duration.should == 4966
    end

    it "should know the display aspect ratio" do
      @video.dar.should == 0.792
    end

    it "should know the pixel aspect ratio" do
      @video.par.should == 1.0
    end

    it "should know the frames per second" do
      @video.fps.should == 30.0
    end

    it "should know the region" do
      pending { @video.region.should == "NTSC" }
    end

    it "should know the size of the stream" do
      @video.size.should == 212293
    end

    it "should know the language" do
      @video.lang.should == 'en'
    end

    it "should know the codec" do
      @video.codec.should == 'MPEG-4 Visual'
    end
  end

  describe MediaInfo::AudioTrack do
    before(:all) do
      @audio = @mediainfo.audio.first
    end

    it "should know the codec" do
      @audio.codec.should == "AAC"
    end

    it "should know the duration" do
      @audio.duration.should == 4992
    end

    it "should know the bitrate" do
      @audio.bitrate.should == 48000
    end

    it "should know the number of channels" do
      @audio.channels.should == 2
    end

    it "should know the samplerate" do
      @audio.samplerate.should == 32000
    end

    it "should know the stream size" do
      @audio.size.should == 30376
    end
  end
end