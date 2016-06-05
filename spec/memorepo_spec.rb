require 'rspec'
require 'rack/test'

require_relative '../io'
require_relative '../pingd'
require_relative '../domain'
require_relative '../repository/interface'

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
    repo.saveProbe(PingResult.new('8.8.8.8', Time.now, 90))

    repo.rtt('8.8.8.8', Time.now.to_i - 5, Time.now.to_i + 5)
  end

  it 'blames on unknown hosts' do
    repo = InMemory.new
    expect { repo.saveProbe(PingResult.new('1.2.3.4', Time.now, 90)) }.to raise_error Storage::MissingHostError
  end
end