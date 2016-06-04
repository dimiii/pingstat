require_relative 'interface'
require_relative '../domain'

class InMemory < Storage
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

  def values
    @hosts
  end

  def saveProbe(pingResult)
    raise MissingHostError.new(pingResult.host) unless @rtt.key? pingResult.host
    puts "RCV #{Time.now.to_f * 1000} #{pingResult}"
    @rtt[pingResult.host].store(pingResult.pingTime,  pingResult.rtt)
  end

  def rtt(host, beginPeriod, endPeriod)
    @rtt[host].select { |ts, rtt| ts >= beginPeriod && ts < endPeriod}.values
  end
end