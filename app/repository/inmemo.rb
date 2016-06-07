require_relative '../domain'

class InMemory
  def initialize(hosts = [])
    @hosts = []
    @rtt = Hash.new
    hosts.each { |host| add(host) }
  end

  def terminate
  end

  def add(host)
    @hosts.push host
    @rtt[host] = Hash.new unless @rtt.key? host
  end

  def delete(host)
    @hosts.delete host
  end

  def hosts
    @hosts
  end

  def saveProbe(pingResult)
    @rtt[pingResult.host].store(pingResult.pingTime.utc.to_i,  pingResult.rtt)
  end

  def rtt(host, beginPeriod, endPeriod)
    begin
      @rtt[host].select { |ts, rtt| ts >= (beginPeriod || 0) && ts.to_i < (endPeriod || 9999999999)}.values
    ensure
      []
    end
  end
end