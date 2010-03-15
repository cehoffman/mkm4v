require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Timestamp do
  it "should parse valid timestamps" do
    stamp = Timestamp.new "03:02:01.321"

    stamp.seconds.should == 3*60*60 + 2*60 + 1.321
    stamp.to_s.should == "03:02:01.321"
  end

  it "should accept timestamps as number of seconds" do
    stamp = Timestamp.new 3*60*60 + 2*60 + 1.321

    stamp.seconds.should == 3*60*60 + 2*60 + 1.321
    stamp.to_s.should == "03:02:01.321"
  end

  it "should have a format of HH:MM:SS.SSS for HH:MM::SS input" do
    stamp = Timestamp.new "00:02:01"

    stamp.to_s.should == "00:02:01.000"
  end

  it "should have a format of HH:MM:SS.SSS for HH:MM::SS.SS input" do
    stamp = Timestamp.new "00:02:01.01"

    stamp.to_s.should == "00:02:01.010"
  end

  it "should have a format of HH:MM:SS.SSS for MM::SS.SS input" do
    stamp = Timestamp.new "02:01.01"

    stamp.to_s.should == "00:02:01.010"
  end

  it "should have a format of HH:MM:SS.SSS for SS.SS input" do
    stamp = Timestamp.new "56.12"

    stamp.to_s.should == "00:00:56.120"
  end

  it "should be comparable" do
    earlier, later = Timestamp.new(0), Timestamp.new(33.2)

    earlier.should < later
    earlier.should == Timestamp.new(0)
    later.should > earlier
  end
end