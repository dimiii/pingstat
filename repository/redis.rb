require 'redis'
require 'thread'
require 'logger'

require_relative 'interface'
require_relative '../domain'

class InRedis < Storage
  # @param driver [Redis]
  def initialize(driver, hosts = [])
    @driver = driver
    @results = Queue.new
    @logger = Logger.new(STDERR)
    @storeThread = Thread.new { storeLoop }
    hosts.each { |host| add(host) }
  end

  def terminate
    @driver.close
    @storeThread.terminate
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
    @results << pingResult
  end

  def rtt(host, beginPeriod, endPeriod)
    beginPeriod = beginPeriod.utc() unless beginPeriod.nil?
    endPeriod = endPeriod.utc() unless endPeriod.nil?

    @driver.zrangebyscore(rttKey(host), beginPeriod || '-inf', endPeriod || '+inf')
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
    # 11 = 10 digits and tab
    # So this repository operates only on data after 09 Sep 2001 01:46:40 UTC required at least 10 digits for encoding
    tsv[11..-1].to_i
  end

  def storeLoop
    @logger.info 'Start background storing loop'
    loop do
      n = @results.size
      next if n == 0

      @driver.pipelined do
        n.times {
          result = @results.deq
          @driver.zadd(rttKey(result.host), result.pingTime.utc, rttVal(result))
        }
      end
    end
  end
end