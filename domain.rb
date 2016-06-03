class PingTask
  attr_reader :secOfMin, :host

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

  def initialize(host, pingTime, rtt)
    @host = host
    @pingTime = pingTime
    @rtt = rtt
  end

  def to_s
    "{host:#{@host}, pinged:#{pingTime}, rtt:#{rtt}}"
  end
end