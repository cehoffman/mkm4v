shared_examples_for "string metadata field" do
  it "should coerce to string when given non string value" do
    @mp4[field] = 2010

    -> { @mp4.save reload: true }.should_not raise_error

    @mp4[field].should == "2010"
  end

  it "should call to_str before to_s to coerce to string" do
    class NonString
      def to_str
        "My Value"
      end

      def to_s
      end
    end

    value = NonString.new
    value.should_not_receive(:to_s)

    @mp4[field] = value
    -> { @mp4.save reload: true }.should_not raise_error
    @mp4[field].should == "My Value"
  end

  it "should raise a helpful TypeError when it can't be coerced" do
    class Unconvertable
      def to_str
        234 # Not a string is the important part
      end

      def to_s
      end
    end

    @mp4[field] = Unconvertable.new
    -> { @mp4.save }.should raise_error(TypeError, "can't convert #{field} to string")

    class Unconvertable
      undef to_str, to_s
    end

    @mp4[field] = Unconvertable.new
    -> { @mp4.save }.should raise_error(TypeError, "can't convert #{field} to string")
  end
end
