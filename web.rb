require 'sinatra/base'
require 'ipaddress'
require 'json'
require 'redis'

require_relative 'pingd'
require_relative 'repository/redis'


class RestResource < Sinatra::Base
  set :logging, true
  set :port, 8080

  service = PingDaemon.new(hostStorage: InRedis.new(Redis.new, batchSize: 100), pingFrequency: 60, operated: true)

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
    halt 400, "Expected ipv4 address, got:#{host}"  unless IPAddress::valid_ipv4? host

    service.delete(host)
  end

  get '/pingstat/summary/:ip' do
    host = params['ip']
    beginPeriod = params['from']
    endPeriod   = params['to']

    halt 400, "Expected ipv4 address, got:#{host}" unless IPAddress::valid_ipv4? host
    halt 400, "Expected number of epoch seconds, got:#{beginPeriod}" unless beginPeriod.nil? or /^\d+$/ =~ params['from']
    halt 400, "Expected number of epoch seconds, got:#{endPeriod}" unless endPeriod.nil? or /^\d+$/ =~ params['to']
    halt 400, 'Expected precedence of time' unless beginPeriod.nil? or endPeriod.nil? or beginPeriod < endPeriod

    summary = service.summary(host, beginPeriod && beginPeriod.to_i, endPeriod && endPeriod.to_i)
    halt 404, 'No data for period' if summary.err?

    summary.to_hash.to_json
  end

  get '/pingstat/op-hosts' do
    service.tasks.keys.to_json
  end

  run! if __FILE__ == $0
end
