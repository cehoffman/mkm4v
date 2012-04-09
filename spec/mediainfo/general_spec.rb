require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MediaInfo::GeneralTrack do
  before(:all) do
    @general = MediaInfo.new(fixtures + "sample_mpeg4.mp4").general.first
  end

  it "should know the path to the opened file" do
    @general.file.should =~ /sample_mpeg4\.mp4$/
  end

  it "should return the path to the opened file as a Pathname" do
    @general.file.should be_an_instance_of(Pathname)
  end

  it "should know the size of the file" do
    @general.size.should == 245779
  end

  it "should know the duration of the whole file" do
    @general.duration.milliseconds.should == 4967
  end

  it "should know the container of the file" do
    @general.container.should == "MPEG-4"
  end

  it "should know the mime type of the file" do
    @general.mime_type.should == "video/mp4"
  end

  it "should know the bitrate of the whole file" do
    @general.bitrate.should == 395859
  end

  it "should have flag if the file is interleaved" do
    @general.interleaved?.should == false
  end
end
