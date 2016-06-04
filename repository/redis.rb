require 'redis'

require_relative 'interface'
require_relative '../domain'

class InRedis < Storage
  # @param driver [Redis]
  def initialize(driver, hosts = [])
    @driver = driver
    #lazyCreateDB(@driver)
    hosts.each { |host| add(host) }
  end

  def terminate
    @driver.close
  end

  def add(host)
    @driver.sadd("operated-hosts", host)
  end

  def delete(host)
    @driver.srem("operated-hosts", host)
  end

  def hosts
    @driver.smembers("operated-hosts")
  end

  def saveProbe(pingResult)
    @driver.zadd(rttKey(pingResult.host), pingResult.pingTime.utc, rttVal(pingResult))
  end

  def rtt(host, beginPeriod, endPeriod)
    @driver.zrangebyscore(rttKey(host), beginPeriod || "-inf", endPeriod || "+inf")
           .map { |tsv| extractRtt(tsv) }
  end

  def rttKey(host)
    "#{host}:rtt"
  end

  def rttVal(pingResult)
    "#{pingResult.pingTime.utc.to_i}\t#{pingResult.rtt}"
  end

  def statusVal(time)
    "#{host}:status"
  end

  def extractRtt(tsv)
    tsv[11..-1].to_i
  end
end