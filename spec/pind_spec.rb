require 'rspec'

require_relative '../pingd'
require 'rack/test'

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

end