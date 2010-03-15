require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Mkm4v::Config do
  include FakeFS::SpecHelpers

  it "should add a parse method to the class" do
    class Test; end

    Test.should_not respond_to(:parse)

    Test.send :include, Mkm4v::Config

    Test.should respond_to(:parse)
  end

  it "should have a config function on class and instances to access parsed options" do
    class Test; include Mkm4v::Config end

    Test.parse *%w(-i file.mkv)

    Test.config.should include(input: ["file.mkv"])
    Test.new.config.should include(input: ["file.mkv"])
  end

  describe "#parse" do
    include FakeFS::SpecHelpers
    include Mkm4v::Config

    def self.flags(*flags, &block)
      desc = flags.pop

      flags.each do |flag|
        flag = flag.length == 1 ? "-#{flag}" : "--#{flag}"

        it "#{flag} should #{desc}" do
          instance_exec flag, &block
        end
      end
    end

    flags :help, :h, "print a help message" do |flag|
      stdout, stderr = capture { -> { self.class.parse flag }.should raise_error(SystemExit) }

      stdout.should == <<-EOS.undent
        Usage: mkm4v [options] -i <filename> [filename ...]
        #{" "}
          --input, -i <s+>:   List of files to convert
             --version, -v:   Print version and exit
                --help, -h:   Show this message
      EOS
    end

    flags :version, :v, "print the curretn version" do |flag|
      stdout, stderr = capture { -> { self.class.parse flag }.should raise_error(SystemExit) }

      stdout.should == "mkm4v Version #{Mkm4v::Version} Copyright (C) 2010 Chris Hoffman\n"
    end

    flags :input, :i, "get a list of input files" do |flag|
      FileUtils.touch "file.mkv"
      FileUtils.touch "file2.mkv"

      self.class.parse flag, "file.mkv", "file2.mkv"

      config.input.should include("file.mkv", "file2.mkv")
    end
  end
end