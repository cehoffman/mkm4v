require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MediaInfo::AudioTrack do
  before(:all) do
    @audio = MediaInfo.new(fixtures + "sample_mpeg4.mp4").audio.first
  end

  it "should know the codec" do
    @audio.codec.should == "AAC"
  end

  it "should know the duration" do
    @audio.duration.milliseconds.should == 4967
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
    @audio.size.should == 30203
  end

  it "should know the language" do
    @audio.lang.should == "en"
  end

  it "should know the track id" do
    @audio.id.should == 1
  end
end
