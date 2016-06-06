require 'redis'
require 'thread'
require 'logger'

require_relative 'interface'
require_relative '../domain'

class InRedis < Storage
  # @param driver [Redis]
  def initialize(driver, batchSize: 100)
    @driver = driver
    @results = Queue.new
    @batchBuffer = []
    @batchSize = batchSize
    @logger = Logger.new(STDERR)
    @storeThread = Thread.new { storeLoop }
    hosts.each { |host| add(host) }
  end

  def terminate
    batchStore
    @driver.close
    @storeThread.terminate
  end

  def add(host)
    @driver.sadd('operated-hosts', host)
  end

  def delete(host)
    @driver.srem('operated-hosts', host)
  end

  def hosts
    @driver.smembers('operated-hosts')
  end

  def saveProbe(pingResult)
    @results << pingResult
  end

  def rtt(host, beginPeriod, endPeriod)
    @driver.zrangebyscore(rttKey(host), beginPeriod || '-inf', endPeriod || '+inf')
           .map { |tsv| extractRtt(tsv) }
  end

  def rttKey(host)
    "#{host}:rtt"
  end

  def rttVal(pingResult)
    "#{pingResult.pingTime.utc.to_i}:#{pingResult.rtt.round(3)}"
  end

  def statusVal(time)
    "#{host}:status"
  end

  def extractRtt(csv)
    # 11 = 10 digits for date and colon
    csv[11..-1].to_i
  end

  def storeLoop
    @logger.info 'Start background storing loop'
    loop do
      result = @results.pop
      next if result.nil?

      @batchBuffer << result
      next if @batchBuffer.size < @batchSize # may be not required in production when massive number of hosts is used

      batchStore
    end
  end

  def batchStore
    @driver.pipelined do
      for result in @batchBuffer do
        @driver.zadd(rttKey(result.host), result.pingTime.utc.to_i, rttVal(result))
      end
    end

    @batchBuffer.clear
  end

  private :storeLoop, :batchStore
end