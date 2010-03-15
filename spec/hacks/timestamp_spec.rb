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

  it "should be comparable with other Timestamps" do
    earlier, later = Timestamp.new(0), Timestamp.new(33.2)

    earlier.should < later
    earlier.should == Timestamp.new(0)
    later.should > earlier
  end

  it "should be comparable with other Numbers" do
    earlier, later = Timestamp.new(0), 33.2

    earlier.should < later
    earlier.should == Timestamp.new(0)
  end

  it "should be addable with other Timestamps" do
    stamp = Timestamp.new(30) + Timestamp.new(21)

    stamp.should be_an_instance_of(Timestamp)
    stamp.seconds.should == 51
  end

  it "should be addable with other numbers" do
    stamp = Timestamp.new(30) + 21

    stamp.should be_an_instance_of(Timestamp)
    stamp.seconds.should == 51
  end

  it "should be subtractable with other Timestamps" do
    stamp = Timestamp.new(30) - Timestamp.new(21)

    stamp.should be_an_instance_of(Timestamp)
    stamp.seconds.should == 9
  end

  it "should be subtractable with other numbers" do
    stamp = Timestamp.new(30) - 21

    stamp.should be_an_instance_of(Timestamp)
    stamp.seconds.should == 9
  end

  it "should have an accessor for number of hours" do
    stamp = Timestamp.new("01:30:00")

    stamp.hours.should == 1.5
  end

  it "should have an accessor for the number of minutes" do
    stamp = Timestamp.new("01:31:00")

    stamp.minutes.should == 91
  end

  it "should have an accessor for the number of milliseconds" do
    stamp = Timestamp.new("00:00:31.232")

    stamp.milliseconds.should == 31232
  end
end