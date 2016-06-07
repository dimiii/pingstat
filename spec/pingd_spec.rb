require 'rspec'
require 'rack/test'

require_relative '../app/pingd'
require_relative '../app/domain'

describe 'Ping Daemon' do
  include Rack::Test::Methods

  it 'adds' do
    pingd = PingDaemon.new
    pingd.add('0.0.0.1')
    pingd.add('0.0.0.2')

    expect(pingd.tasks.values.size).to eq 2
  end

  it 'deletes' do
    pingd = PingDaemon.new

    pingd.delete('0.0.0.1')
    expect(pingd.tasks.values.size).to eq 0

    pingd.add('0.0.0.1')
    expect(pingd.tasks.values.size).to eq 1

    pingd.delete('0.0.0.1')
    expect(pingd.tasks.values.size).to eq 0
  end

  it 'restores tasks from repository' do
    hosts = InMemory.new
    (1..182).each do |i|
      hosts.add "0.0.0.#{i}"
    end
    pingd = PingDaemon.new(host_storage: hosts)

    expect(pingd.schedule[0].size).to eq 5
    expect(pingd.schedule[1].size).to eq 3
    expect(pingd.schedule[2].size).to eq 3
  end

end