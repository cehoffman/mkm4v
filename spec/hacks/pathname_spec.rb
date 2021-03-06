require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Pathname do
  before(:all) do
    @path = Pathname.new(__FILE__)
  end

  it "should respond to to_str" do
    @path.should respond_to(:to_str)
  end

  it "should have to_str equal to_s" do
    @path.to_str.should == @path.to_s
  end

  it "should create a new pathname object with new extension" do
    saved = @path
    newpath = @path.extname "new"

    saved.should_not == newpath
    newpath.basename.should == Pathname.new("pathname_spec.new")
  end

  it "should allow reading of extension" do
    @path.extname.should == ".rb"
  end

  it "should be create temporary files in the system tmpdir" do
    tmp = Pathname.tmpfile @path
    tmp.to_s.should =~ /^#{Regexp.escape(Dir::tmpdir)}/
  end

  it "should create temporary files with the basename of file" do
    tmp = Pathname.tmpfile @path
    tmp.to_s.should =~ /^#{Regexp.escape(Dir::tmpdir)}\/#{@path.basename}/
  end

  it "should create temporary files with given extension if given" do
    tmp = Pathname.tmpfile @path, "tmp"
    tmp.to_s.should =~ /#{@path.extname("tmp").basename}$/
  end

  it "should be comparable with regexs" do
    @path.should respond_to(:=~)
    @path.should =~ /pathname_spec\.rb$/
  end

  it "should have a [regex, item] accessor" do
    @path[/(pathname_spec\.rb)$/, 1].should == "pathname_spec.rb"
  end
end