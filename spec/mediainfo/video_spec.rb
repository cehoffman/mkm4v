require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MediaInfo::VideoTrack do
  before(:all) do
    @video = MediaInfo.new(fixtures + "sample_mpeg4.mp4").video.first
  end

  it "should know the height" do
    @video.height.should == 240
  end

  it "should know the width" do
    @video.width.should == 190
  end

  it "should know the duration" do
    @video.duration.milliseconds.should == 4967
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

  it "should know the number of frames" do
    @video.frames.should == 149
  end

  it "should know the bitrate" do
    @video.bitrate.should == 341948
  end

  it "should have a shortcut for ntsc region" do
    @video.ntsc?.should == false
  end

  it "should have a shortcut for pal region" do
    @video.pal?.should == false
  end

  it "should have a shortcut for interlaced" do
    @video.interlaced?.should == false
  end
end
