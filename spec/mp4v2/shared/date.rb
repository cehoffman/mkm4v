shared_examples_for "date metadata field" do
  it "should coerce strings to datetime" do
    @mp4[field] = "2004-11-27T04:00:01Z"

    -> { @mp4.save reload: true }.should_not raise_error

    @mp4[field].should == DateTime.civil(2004, 11, 27, 4, 0, 1)
  end

  it "should raise an error when unable to parse string" do
    @mp4[field] = "Some garbage"

    -> { @mp4.save }.should raise_error(TypeError, "can't convert #{field} to DateTime")
  end
end
