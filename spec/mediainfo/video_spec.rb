require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MediaInfo::VideoTrack do
  before(:all) do
    @video = MediaInfo.new(File.expand_path("../../fixtures/sample_mpeg4.mp4", __FILE__)).video.first
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

  it "should know the track id" do
    @video.id.should == 2
  end
end