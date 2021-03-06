require 'rspec'
require 'rack/test'

require_relative '../app/web'

describe 'Web application' do
  include Rack::Test::Methods

  def app
    RestResource.new(service: PingDaemon.new)
  end

  it 'should be alive' do
    get '/pingstat'

    expect(last_response.body).to include 'Hi!'
  end

  it 'understands ip4 notation' do
    put '/pingstat/add/1.2.3.4'

    expect(last_response).to be_ok
  end

  it 'does not understand wrong ip4 notation' do
    put '/pingstat/add/1.2.3.4.5'
    expect(last_response).to_not be_ok

    put '/pingstat/del/1.2.3.4.5'
    expect(last_response).to_not be_ok
  end

  it 'does not understand wrong timestamps' do
    get '/pingstat/summary/1.2.3.4?from=A'
    expect(last_response).to_not be_ok

    get '/pingstat/summary/1.2.3.4?to=B'
    expect(last_response).to_not be_ok

    get '/pingstat/summary/1.2.3.4?from=2&to=1'
    expect(last_response).to_not be_ok
  end

  it 'calculates summary if can' do
    get '/pingstat/summary/1.2.3.4?from=1&to=2'
    expect(last_response.body).to include 'No data for period'
  end

  it 'collects ip' do
    1.upto(120) do |i|
      put "/pingstat/add/1.2.3.#{i}"
      expect(last_response).to be_ok
    end
  end
end