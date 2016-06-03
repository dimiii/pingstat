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