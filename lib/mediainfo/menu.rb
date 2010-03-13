class MediaInfo::MenuTrack < MediaInfo::AbstractTrack
  attr_reader :chapters

  def initialize(source, track)
    super
    @chapters = []
    start, stop = info('Chapters_Pos_Begin').to_i, info('Chapters_Pos_End').to_i
    (start...stop).each { |i| @chapters.push Timestamp.new(info(i).split(':', 2).last) }
  end
end

class Timestamp
  include Comparable

  attr_reader :seconds

  def initialize(stamp)
    if stamp.is_a?(Numeric)
      @seconds = stamp
    else
      raise ArgumentError, "invalid timestamp format '#{stamp}'" unless self.class.valid?(stamp)
      @seconds = stamp.split(':').reverse.inject({:sum => 0.0, :unit => 1.0}) do |held, part|
        held[:sum] += held[:unit]*part.to_f
        held[:unit] *= 60
        held
      end[:sum]
    end
  end

  def self.valid?(stamp)
    !stamp.nil? && stamp =~ /^((\d+)?:?\d+)?:?\d+(\.\d+)?$/
  end

  def <=>(other)
    @seconds - other.seconds
  end

  def to_s
    num = @seconds

    hours = (num/(60*60)).to_i
    num -= hours*(60*60)

    minutes = (num/60).to_i
    num -= minutes*60
    secs = num.to_i
    num -= secs

    "%02d:%02d:%02d%s" % [hours, minutes, secs, ("%.03f" % num)[1..-1]]
  end
end