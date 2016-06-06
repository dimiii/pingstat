class PingTask
  attr_reader :secOfMin, :host

  # @param host [String]
  # @param secOfMin [Number]
  def initialize(host, secOfMin)
    @secOfMin = secOfMin % 60
    @host = host
  end

  def to_s
    "{host: #{@host}, scheduled:#{@secOfMin}}"
  end
end

class PingResult
  attr_reader :pingTime, :rtt, :host

  # @param host [String]
  # @param pingTime [Time]
  # @param rtt [Number]
  def initialize(host, pingTime, rtt)
    @host = host
    @pingTime = pingTime
    @rtt = rtt
  end

  def to_s
    "{host:#{@host}, pinged:#{pingTime}, rtt:#{rtt}}"
  end
end

class SummaryReport
  attr_reader :avg, :min, :max, :med, :sd, :los

  # @param vals [Array]
  def initialize(vals = [], beginPeriod, endPeriod, pingFrequency, precision: 2)
    numExpectedPings = (endPeriod.to_i - beginPeriod.to_i) / pingFrequency unless beginPeriod.nil? or endPeriod.nil?
    @loss= 1 - vals.size.to_f / numExpectedPings unless numExpectedPings.nil? or numExpectedPings == 0
    @precision = precision
    @isErr = vals.empty?

    calcRttMetrics(vals) unless @isErr
  end

  def calcRttMetrics(vals)
    sorted = vals.sort
    center = sorted.size / 2

    @avg = vals.reduce(:+).to_f / vals.size
    @min = vals.min
    @max = vals.max
    @med = vals.size.even? ? (sorted[center] + sorted[center - 1]) / 2.0 : sorted[center]
    @sd = Math.sqrt(vals.map { |v| (v - @avg)**2 }.reduce(:+).to_f / (vals.size - 1)) if vals.size > 1
  end

  def err?
    @isErr
  end

  def to_hash
    {:rtt => {:avg => round(@avg, @precision),
              :min => round(@min, @precision),
              :max => round(@max, @precision),
              :med => round(@med, @precision),
              :sd  => round(@sd, @precision)},
     :loss => round(@loss, @precision)
    }
  end

  def round(v, precision)
    v.round(precision) unless v.nil?
  end
end