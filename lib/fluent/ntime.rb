class Fluent::NTime
  def initialize(sec, nsec = 0)
    @sec = sec
    @nsec = nsec
  end

  def ==(other)
    if other.is_a?(Fluent::NTime)
      @sec == other.sec
    else
      @sec == other
    end
  end

  def sec
    @sec
  end

  def nsec
    @nsec
  end

  def to_int
    @sec
  end

  # for Time.at
  def to_r
    Rational(@sec * 1_000_000_000 + @nsec, 1_000_000_000)
  end

  # for > and others
  def coerce(other)
    [other, @sec]
  end

  def to_s
    @sec.to_s
  end

  def self.from_time(time)
    Fluent::NTime.new(time.to_i, time.nsec)
  end

  def self.now
    from_time(Time.now)
  end

  ## TODO: For performance, implement +, -, and so on
  def method_missing(name, *args, &block)
    @sec.send(name, *args, &block)
  end
end
