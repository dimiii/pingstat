require 'redis'
require 'thread'
require 'logger'

require_relative '../domain'

# Redis storage abstraction layer.
class InRedis
  def initialize(driver, batch_size: 100)
    @driver = driver
    @results = Queue.new
    @batch_buffer = []
    @batch_size = batch_size
    @logger = Logger.new(STDERR)
    @store_thread = Thread.new { store_loop }
    hosts.each { |host| add(host) }
  end

  def terminate
    batch_store
    @driver.close
    @store_thread.terminate
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

  def save_probe(ping_result)
    @results << ping_result
  end

  def rtt(host, begin_period, end_period)
    @driver.zrangebyscore(rtt_key(host), begin_period || '-inf', end_period || '+inf')
           .map { |csv| extract_rtt(csv) }
  end

  def rtt_key(host)
    "#{host}:rtt"
  end

  def rtt_val(ping_result)
    "#{ping_result.ping_time.utc.to_i}:#{ping_result.rtt.round(3)}"
  end

  def extract_rtt(csv)
    # 11 = 10 digits for date and colon
    csv[11..-1].to_i
  end

  def store_loop
    @logger.info 'Start background storing loop'
    loop do
      result = @results.pop
      next if result.nil?

      @batch_buffer << result
      next if @batch_buffer.size < @batch_size # may be not required in production when massive number of hosts is used

      batch_store
    end
  end

  def batch_store
    @driver.pipelined do
      @batch_buffer.each { |result| @driver.zadd(rtt_key(result.host), result.ping_time.utc.to_i, rtt_val(result)) }
    end
    @logger.debug "Stored #{@batch_buffer.size} items: [#{@batch_buffer[0].host}, ...]" unless @batch_buffer.empty?
    @batch_buffer.clear
  end

  private :store_loop, :batch_store, :rtt_key, :rtt_val
end