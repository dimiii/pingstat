class Storage
  MESS = 'SYSTEM ERROR: method missing'
  class MissingHostError < StandardError

  end

  def terminate; raise MESS; end;

  def method_one; raise MESS; end
  def method_two; raise MESS; end

  def add(host); raise MESS; end
  def delete(host); raise MESS; end
  def values; raise MESS; end

  # @param pingResult [PingResult]
  def saveProbe(pingResult); raise MESS; end

  def rtt(host); raise MESS; end
end