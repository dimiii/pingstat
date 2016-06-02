
class InMemory
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
end