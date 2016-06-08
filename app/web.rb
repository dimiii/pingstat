require 'sinatra/base'
require 'ipaddress'
require 'json'
require 'redis'

require_relative 'pingd'
require_relative 'repository/redis'

# REST access to pingstat application.
class RestResource < Sinatra::Base
  set :logging, true
  set :port, 8080

  service = PingDaemon.new(host_storage: InRedis.new(Redis.new, batch_size: 100), ping_frequency: 60, operated: true)

  get '/pingstat' do
    'Hi!'
  end

  put '/pingstat/add/:ip' do
    host = params['ip']
    halt 400, "Expected ipv4 address, got:#{host}" unless IPAddress::valid_ipv4? host

    service.add(host)
  end

  put '/pingstat/del/:ip' do
    host = params['ip']
    halt 400, "Expected ipv4 address, got:#{host}" unless IPAddress::valid_ipv4? host

    service.delete(host)
  end

  get '/pingstat/summary/:ip' do
    host = params['ip']
    begin_period = params['from']
    end_period   = params['to']

    halt 400, "Expected ipv4 address, got:#{host}" unless IPAddress::valid_ipv4? host
    halt 400, "Expected number of epoch seconds, got:#{begin_period}" unless begin_period.nil? or /^\d+$/ =~ params['from']
    halt 400, "Expected number of epoch seconds, got:#{end_period}" unless end_period.nil? or /^\d+$/ =~ params['to']
    halt 400, 'Expected precedence of time' unless begin_period.nil? or end_period.nil? or begin_period < end_period

    summary = service.summary(host, begin_period && begin_period.to_i, end_period && end_period.to_i)
    halt 404, 'No data for period' if summary.err?

    summary.to_hash.to_json
  end

  get '/pingstat/op-hosts' do
    service.tasks.keys.to_json
  end

  run! if __FILE__ == $PROGRAM_NAME
end
