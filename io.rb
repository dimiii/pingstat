require 'rufus-scheduler'
require 'nio'
require 'socket'
require 'logger'
require 'thread'

require_relative 'repository/interface'

include Socket::Constants
class PingIO

  ICMP_ECHOREPLY = 0
  ICMP_ECHO      = 8
  ICMP_SUBCODE   = 0

  # @param hostStorage [Storage]
  def initialize(hostStorage)
    @hostStorage = hostStorage
    @selector = NIO::Selector.new
    @scheduler = Rufus::Scheduler.new(:max_work_threads => 1)
    @logger = Logger.new(STDERR)
  end

  def operate(schedule, pingFrequency)
    @pingFrequency = pingFrequency
    @schedule = schedule

    @pingThread = Thread.new {  pingSendLoop } if @pingThread.nil?
    @replyThread =  Thread.new { replyReceiveLoop } if @replyThread.nil?

    @pingThread.join()
    @replyThread.join()

  end

  def terminate
    begin
      @scheduler.shutdown
    rescue
      @logger.error 'Failed close nio4r selector'
    end

    begin
      @selector.close
    rescue
      @logger.error 'Failed close nio4r selector'
    end

    @pingThread.terminate
    @replyThread.terminate
  end


  def pingSendLoop
    @logger.info 'Start ping loop'

    opSecond = 0
    @scheduler.every '1s' do
      @schedule[opSecond].each { |task| ping(task) } unless @schedule[opSecond].nil?

      opSecond += 1
      opSecond %= @pingFrequency
    end

    @scheduler.join
    @logger.info 'Stop ping loop'
  end

  def replyReceiveLoop
    @logger.info 'Start reply loop'
    loop do

      if not @selector.nil?
        @selector.wakeup # give a chance to register sockets in pingLoop
        @selector.select { |monitor| monitor.value.call(monitor) }
        # nio4r selector is a weak chain here - it swallows err events (and does not allow to classify them)
        # and does not block without timeout (due to err-evt?)
        # it does not allow to unregister socket on error, created with a good intentions it hides
        # possibility of batch operations. May be Kernel.select is a better way of operating
      end
    end

    @logger.info 'Stop reply loop'
  end

  def ping(task)
    socket = Socket.new(PF_INET, SOCK_RAW, IPPROTO_ICMP)
    sockaddr = Socket.sockaddr_in(1984, task.host) # port does not matter
    socket.connect(sockaddr)

    msg = [ICMP_ECHO, ICMP_SUBCODE, 0, 42, 1, 'wow such raw so socket'].pack('C2 n3 A*')
    msg[2..3] = [checksum(msg)].pack('n')

    monitor = @selector.register(socket, :r)
    pingTime = Time.now
    monitor.value = proc { onReceive(socket, pingTime, task.host) }
    socket.sendmsg_nonblock(msg)
  end

  def onReceive(socket, pingTime, host)
    rtt = (Time.now() - pingTime) * 1000
    @hostStorage.saveProbe(PingResult.new(host, pingTime, rtt))

    @selector.deregister(socket)
    socket.close
  rescue EOFError
    @selector.deregister(socket)
    socket.close
  rescue Storage::MissingHostError
    @logger.error "Unknown host #{host}, chekck db consistency"
  end

  def checksum(msg)
    length    = msg.length
    num_short = length / 2
    check     = 0

    msg.unpack("n#{num_short}").each do |short|
      check += short
    end

    if length % 2 > 0
      check += msg[length-1, 1].unpack('C').first << 8
    end

    check = (check >> 16) + (check & 0xffff)
    return (~((check >> 16) + check) & 0xffff)
  end

  private :pingSendLoop, :replyReceiveLoop, :ping, :onReceive, :checksum

end