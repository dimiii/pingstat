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

  def save_probe(ping_result)
    @rtt[ping_result.host].store(ping_result.ping_time.utc.to_i,  ping_result.rtt)
  end

  def rtt(host, begin_period, end_period)
    begin
      @rtt[host].select { |ts, _| ts >= (begin_period || 0) && ts.to_i < (end_period || 9999999999)}.values
    ensure
      []
    end
  end
end