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
    case other
    when Timestamp then @seconds - other.seconds
    when Numeric then @seconds - other
    else raise ArgumentError, "comparision of Timestamp with #{other.class}"
    end
  end

  def +(other)
    case other
    when Timestamp then Timestamp.new @seconds + other.seconds
    when Numeric then Timestamp.new @seconds + other
    else
      other.respond_to(:to_i) && Timestamp.new(@secons + other) || raise(TypeError, "#{other.class} can't be coerced into a Fixnum")
    end
  end

  def -(other)
    case other
    when Timestamp then Timestamp.new @seconds - other.seconds
    when Numeric then Timestamp.new @seconds - other
    else
      other.respond_to(:to_i) && Timestamp.new(@secons - other) || raise(TypeError, "#{other.class} can't be coerced into a Fixnum")
    end
  end

  def hours
    @seconds/3600.0
  end

  def minutes
    @seconds/60.0
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