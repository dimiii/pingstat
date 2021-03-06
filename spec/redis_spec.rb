require 'rspec'
require 'rack/test'
require 'fakeredis'

require_relative '../app/domain'
require_relative '../app/repository/redis'

describe 'Redis Repository' do
  include Rack::Test::Methods

  probes = [
      PingResult.new('8.8.8.8', Time.parse('2012-12-12T06:06'), 82),
      PingResult.new('8.8.8.8', Time.parse('2012-12-12T06:07'), 81),
      PingResult.new('8.8.8.8', Time.parse('2012-12-12T06:08'), 127),
      PingResult.new('8.8.8.8', Time.parse('2012-12-12T06:09'), 81),
      PingResult.new('8.8.8.8', Time.parse('2012-12-12T07:07'), 81)
  ]

  it 'remembers hosts' do
    repo = InRedis.new(Redis.new)
    repo.add('8.8.8.8')

    expect(repo.hosts.size).to eq 1
    repo.terminate
  end

  it 'forgets hosts' do
    repo = InRedis.new(Redis.new)
    repo.add('8.8.8.8')
    repo.delete('8.8.8.8')
    expect(repo.hosts.size).to eq 0
    repo.terminate
  end

  it 'collects stats' do
    repo = InRedis.new(Redis.new, batch_size: 2)
    repo.add('8.8.8.8')
    probes.each do |probe| repo.save_probe(probe) end

    sleep 1 # give a chance to store
    expect(repo.rtt('8.8.8.8', Time.parse('2012-12-12T06:06'), Time.parse('2012-12-12T06:09'))).to eq [82, 81, 127, 81]
    repo.terminate
  end

  it 'operates only on data after Sun, 09 Sep 2001 01:46:40 UTC' do
    repo = InRedis.new(Redis.new)
    expect(repo.extract_rtt("1000000000\t1")).to eq 1

    # For example, store data timestamped a second before and we lose data.
    # Cause the time machine is not invented yet - not a big deal.
    expect(repo.extract_rtt("999999999\t7")).to eq 0
    repo.terminate
  end
end