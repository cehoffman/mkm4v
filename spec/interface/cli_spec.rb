require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Mkm4v::Cli do
  include FakeFS::SpecHelpers
  include Mkm4v::Config

  it "should include Mkm4v::Config for option parsing" do
    Mkm4v::Cli.included_modules.should include(Mkm4v::Config)

    Mkm4v::Cli.stub!(:config).and_return({input: []})
    Mkm4v::Cli.should_receive(:parse)

    capture { Mkm4v::Cli.run *%w(-i file.mp4) }
  end

  it "should warn if a file doesn't exist" do
    stdout, stderr = capture { Mkm4v::Cli.run *%w(-i file.mp4) }

    stderr.should =~ /\Afile\.mp4 does not exist/
  end

  it "should remove files that don't exist from processing list" do
    capture { Mkm4v::Cli.run *%w(-i file.mp4) }

    config.input.should_not include("file.mp4")
  end
end