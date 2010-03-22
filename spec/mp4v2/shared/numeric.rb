Maximum = { genre_type: 2**16, tempo: 2**16, season: 2**32, episode: 2**32,
            account_type: 256, country: 2**32, cnID: 2**32, atID: 2**32,
            plID: 2**64, geID: 2**32, track: 2**16, tracks: 2**16, disk: 2**16,
            disks: 2**16 }

shared_examples_for "numeric metadata field" do
  it "should coerce to integer when given non integer" do
    @mp4[field] = "25"

    -> { @mp4.save reload: true }.should_not raise_error

    @mp4[field].should == 25
  end

  it "should raise error when setting number above max range of field" do
    @mp4[field] = Maximum[field]

    -> { @mp4.save }.should raise_error(RangeError, "#{field} max value is #{Maximum[field] - 1}")
  end

  it "should call to_int before to_i to coerce to integer" do
    class NonFixnum
      def to_int
        235
      end

      def to_i
      end
    end

    value = NonFixnum.new
    value.should_not_receive(:to_i)
    @mp4[field] = value

    -> { @mp4.save reload: true }.should_not raise_error

    @mp4[field].should == 235
  end

  it "should raise a helpful TypeError when it can't be coerced" do
    class Unconvertable
      def to_int
        "Not an integer"
      end
    end

    @mp4[field] = Unconvertable.new

    -> { @mp4.save }.should raise_error(TypeError, "can't convert #{field} to integer")

    class Unconvertable
      undef to_int
    end

    @mp4[field] = Unconvertable.new

    -> { @mp4.save }.should raise_error(TypeError, "can't convert #{field} to integer")
  end
end
