require 'rspec'
require 'rack/test'

require_relative '../app/io'
require_relative '../app/pingd'
require_relative '../app/domain'

describe 'InMemory Repository' do
  include Rack::Test::Methods

  it 'remembers hosts' do
    repo = InMemory.new
    repo.add('8.8.8.8')
    expect(repo.hosts.size).to_not eq 0
  end

  it 'forgets hosts' do
    repo = InMemory.new
    repo.add('8.8.8.8')
    repo.delete('8.8.8.8')
    expect(repo.hosts.size).to eq 0
  end

  it 'collects stats' do
    repo = InMemory.new
    repo.add('8.8.8.8')
    repo.save_probe(PingResult.new('8.8.8.8', Time.now, 90))

    repo.rtt('8.8.8.8', Time.now.to_i - 5, Time.now.to_i + 5)
  end
end