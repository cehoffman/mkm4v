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

  it "should know the file it opened" do
    @mp4.file.should =~ /\/mp4v2\.test$/
  end
end