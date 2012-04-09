shared_examples_for "generic metadata field" do
  it "should be settable with #{class_variable_get(:@@setter).class} and gettable as #{class_variable_get(:@@getter).class}" do
    @current = self.class.class_variable_get(:@@current)[field]

    @mp4[field] = setter
    @mp4.save reload: true
    @mp4[field].should == getter

    self.class.class_variable_get(:@@current)[field] = @current + 1
  end
end
