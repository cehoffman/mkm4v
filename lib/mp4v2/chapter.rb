class Mp4v2::Chapter
  include Comparable

  attr_reader :timestamp
  attr_accessor :title

  def initialize(timestamp, title)
    @timestamp = Timestamp.new timestamp
    @title = title
  end

  def <=>(other)
    @timestamp - other.timestamp
  end

  def inspect
    "#<#{self.class} #@title at #@timestamp>"
  end
end