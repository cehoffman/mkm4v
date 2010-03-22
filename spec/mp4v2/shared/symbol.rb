shared_examples_for "symbol metadata field" do
  it "should coerce to symbol" do
    convertable = Class.new do
                      define_method :to_sym do
                        setter
                      end
                    end

    @mp4[field] = convertable.new

    -> { @mp4.save reload: true }.should_not raise_error

    @mp4[field].should == setter
  end

  it "should raise a helpful TypeError when it can't coerce to symbol" do
    class Unconvertable
      def to_sym
        "not a symbol"
      end
    end

    @mp4[field] = Unconvertable.new

    -> { @mp4.save reload: true }.should raise_error(TypeError, "can't convert #{field} to symbol")

    class Unconvertable
      undef to_sym
    end

    @mp4[field] = Unconvertable.new

    -> { @mp4.save reload: true }.should raise_error(TypeError, "can't convert #{field} to symbol")
  end

  it "should not be set when invalid" do
    @mp4.kind = :invalid
    @mp4.save reload: true
    @mp4.should_not have_key(:kind)
  end
end
