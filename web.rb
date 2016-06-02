require 'sinatra/base'
require 'ipaddress'
require_relative 'pingd'


class RestResource < Sinatra::Base
  set :logging, true
  set :port, 8080

  def initialize(app = nil, service = PingDaemon.new)
    super(app)
    @service = service
  end

  get '/pingstat' do
    'Hi!'
  end

  put '/pingstat/add/:ip' do
    host = params['ip']
    halt 400, "Expected ipv4 address, got:#{host}" unless IPAddress::valid_ipv4? host

    @service.add(host)
  end

  put '/pingstat/del/:ip' do
    host = params['ip']
    halt 400, "Expected ipv4 address, got:#{host}"  unless IPAddress::valid_ipv4? host

    @service.delete(host)
  end

  get '/pingstat/summary/:ip' do
    host = params['ip']
    from = params['from'].to_i
    to   = params['to'].to_i   #TODO from/to checking
    halt 400, "Expected ipv4 address, got:#{host}" unless IPAddress::valid_ipv4? host

    @service.summary(host, from, to)
  end

  get '/pingstat/op-hosts' do
    @service.tasks.values.to_a
  end

  run! if __FILE__ == $0
end

RestResource.new

