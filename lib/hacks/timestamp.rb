class Timestamp
  include Comparable

  attr_reader :milliseconds

  def initialize(stamp)
    if stamp.is_a?(Numeric)
      @milliseconds = stamp
    else
      raise ArgumentError, "invalid timestamp format '#{stamp}'" unless self.class.valid?(stamp)
      @milliseconds = stamp.split(':').reverse.inject({:sum => 0.0, :unit => 1.0}) do |held, part|
        held[:sum] += held[:unit]*part.to_f
        held[:unit] *= 60
        held
      end[:sum]*1000
    end

    @milliseconds = @milliseconds.to_i
  end

  def self.valid?(stamp)
    !stamp.nil? && stamp =~ /^((\d+)?:?\d+)?:?\d+(\.\d+)?$/
  end

  def <=>(other)
    @milliseconds - other
  end

  def +(other)
    case other
    when Timestamp then Timestamp.new(@milliseconds + other.milliseconds)
    else
      other.respond_to?(:coerce) && Timestamp.new(@milliseconds + other.coerce(@milliseconds)) || raise(TypeError, "#{other.class} can't be coerced into a Fixnum")
    end
  end

  def -(other)
    case other
    when Timestamp then Timestamp.new(@milliseconds - other.milliseconds)
    else
      other.respond_to?(:coerce) && Timestamp.new(@milliseconds - other.coerce(@milliseconds)) || raise(TypeError, "#{other.class} can't be coerced into a Fixnum")
    end
  end

  def hours
    @milliseconds/3600000.0
  end

  def minutes
    @milliseconds/60000.0
  end

  def seconds
    @milliseconds/1000.0
  end

  # This is for ducktyping to a number
  def coerce(num)
    @milliseconds.coerce(num)
  end

  alias_method :to_i, :milliseconds

  def to_s
    "%02d:%02d:%02d.%03d" % [hours.to_i, minutes % 60, seconds % 60, milliseconds % 1000]
  end
  alias_method :to_str, :to_s
end