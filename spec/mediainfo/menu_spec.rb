require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MediaInfo::MenuTrack do
  before(:all) do
    @menu = MediaInfo.new(fixtures + "dts.mkv").menu.first
  end

  it "should have a list of chapters" do
    @menu.chapters.should be_an_instance_of(Array)
  end

  it "each chapter should be a timestamp" do
    @menu.chapters.each { |chap| chap.should be_an_instance_of(Timestamp) }
  end
end