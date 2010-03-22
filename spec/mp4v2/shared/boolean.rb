shared_examples_for "boolean metadata field" do
  it "should have a boolean accessor using ruby truths" do
    @mp4.send("#{field}?".to_sym).should == false

    @mp4[field] = "A truth value"

    @mp4.send("#{field}?").should == true

    @mp4[field] = nil

    @mp4.send("#{field}?").should == false
  end
end
