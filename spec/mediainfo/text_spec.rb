require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MediaInfo::TextTrack do
  before(:all) do
    @text = MediaInfo.new(File.expand_path("../../fixtures/dts.mkv", __FILE__)).text.first
  end

  it "should know the language of the track" do
    @text.lang.should == "en"
  end

  it "should know the encoding of the track" do
    @text.encoding.should == Encoding::UTF_8
  end

  it "should know the track id" do
    @text.id.should == 3
  end
end