require 'rspec'
require 'rack/test'

require_relative '../app/io'
require_relative '../app/pingd'
require_relative '../app/domain'

describe 'Ping IO' do
  include Rack::Test::Methods

  test_list = %w(8.8.8.8          174.121.194.34   212.58.241.131  198.78.201.252  72.247.244.88   173.231.140.219
                 74.125.157.99    74.125.65.91     98.137.149.56   65.55.72.135    65.55.175.254   64.191.203.30
                 65.39.178.43     216.239.113.172  69.10.25.46     98.124.248.77   144.198.29.112  207.97.227.239
                 80.94.76.5       93.158.65.211    62.149.24.66    62.149.24.67    69.171.224.11   199.59.149.230
                 209.200.154.225  69.174.244.50    67.201.54.151   84.22.170.149   199.9.249.21    184.173.141.231
                 208.94.146.80    174.140.154.32   178.17.165.74   91.220.176.248  91.220.176.248  208.223.219.206
                 72.21.211.176    216.52.208.187   209.31.22.39    205.196.120.13  174.140.154.20  208.87.33.151
                 195.191.207.40   31.7.57.13       199.7.177.218   69.10.25.46     67.21.232.223   178.162.238.136
                 95.211.143.200   199.47.217.179   69.65.13.216    97.107.137.164  194.71.107.15   174.121.194.34
                 97.107.132.144   208.87.33.151    95.211.149.7    89.238.130.247)

  it 'sends something' do
    if Process.uid > 0 and (/darwin/ =~ RUBY_PLATFORM).nil?
      raise 'Must run as root or with CAP_NET_RAW+eip capability, because raw sockets are utilized'
    end

    schedule = { 0 => test_list.map { |host| PingTask.new(host, 0) } }
    storage = InMemory.new(test_list)

    io = PingIO.new(storage)
    Thread.new { io.operate(schedule, 4, 1024) }
    start_time = Time.now.to_i
    sleep 2
    expect(storage.rtt('8.8.8.8', start_time, Time.now.to_i).size).to eq 1
    io.terminate
  end

  it 'operates and terminates' do
    io = PingIO.new(InMemory.new)
    Thread.new { io.operate({}, 1) }
    io.terminate
  end

  it 'traces limits on count of tasks' do
    io = PingIO.new(InMemory.new)
    trash_bag = Hamster::Hash.new
    (0..5).each do |i|
      sock = double("sock_#{i}")
      task = PingTask.new("8.8.8.#{i}", 0)
      trash_bag = trash_bag.put(sock, TaskProgress.new(task, i * 10))
      allow(sock).to receive(:close)
    end

    expect(io.cleanup_oldest(trash_bag, 3).size).to eq 1
    expect(io.cleanup_oldest(trash_bag, 4).size).to eq 2
  end
end

