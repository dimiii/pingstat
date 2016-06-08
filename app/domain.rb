# The subject of ping scheduling.
class PingTask
  attr_reader :opsecond, :host

  # @param host [String]
  # @param opsecond [Number]
  def initialize(host, opsecond)
    @opsecond = opsecond
    @host = host
  end

  def to_s
    "{host: #{@host}, opsecond:#{@opsecond}}"
  end
end

# The progress of ping. Used to trace timeouts.
class TaskProgress
  attr_reader :task, :ttl

  # @param task [PingTask]
  def initialize(task, ttl = 0)
    @task = task
    @ttl  = ttl
  end

  def hop
    @ttl += 1
    self
  end

  def to_s
    "{host:#{@task.host}, ttl:#{@ttl}}"
  end
end

# Traits of ping.
class PingResult
  attr_reader :ping_time, :rtt, :host

  # @param host [String]
  # @param ping_time [Time]
  # @param rtt [Number]
  def initialize(host, ping_time, rtt)
    @host = host
    @ping_time = ping_time
    @rtt = rtt
  end

  def to_s
    "{host:#{@host}, pinged:#{ping_time}, rtt:#{rtt}}"
  end
end

# The subject of user interest.
class SummaryReport
  attr_reader :avg, :min, :max, :med, :sd, :loss

  # @param vals [Array]
  def initialize(vals = [], begin_period, end_period, ping_frequency, precision: 2)
    is_open_interval = begin_period.nil? or end_period.nil?
    num_pings_expected = (end_period.to_i - begin_period.to_i) / ping_frequency unless is_open_interval
    @loss= 1 - vals.size.to_f / num_pings_expected unless num_pings_expected.nil? or num_pings_expected == 0
    @precision = precision
    @is_err = vals.empty?

    calc_rtt_metrics(vals) unless @is_err
  end

  def calc_rtt_metrics(vals)
    sorted = vals.sort
    center = sorted.size / 2

    @avg = vals.reduce(:+).to_f / vals.size
    @min = vals.min
    @max = vals.max
    @med = vals.size.even? ? (sorted[center] + sorted[center - 1]) / 2.0 : sorted[center]
    @sd = Math.sqrt(vals.map { |v| (v - @avg)**2 }.reduce(:+).to_f / (vals.size - 1)) if vals.size > 1
  end

  def err?
    @is_err
  end

  def to_hash
    { :rtt => { :avg => round(@avg, @precision),
                :min => round(@min, @precision),
                :max => round(@max, @precision),
                :med => round(@med, @precision),
                :sd  => round(@sd, @precision) },
      :loss => round(@loss, @precision)
    }
  end

  def round(v, precision)
    v.round(precision) unless v.nil?
  end
end