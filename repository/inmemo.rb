require_relative 'interface'
require_relative '../domain'

class InMemory < Storage
  def initialize
    @hosts = []
  end

  def add(host)
    @hosts.push host
  end

  def delete(host)
    @hosts.delete host
  end

  def values
    @hosts
  end

  def saveProbe(pingResult)
    puts "RCV #{Time.now.to_f * 1000} #{pingResult}"
  end

  def rtt(host, beginPeriod, endPeriod)

  end
end