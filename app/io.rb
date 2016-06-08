require 'rufus-scheduler'
require 'nio'
require 'socket'
require 'logger'
require 'thread'
require 'hamster'

include Socket::Constants

# Manages execution of ping thru network with a specified schedule and frequency.
class PingIO

  ICMP_ECHOREPLY = 0
  ICMP_ECHO      = 8
  ICMP_SUBCODE   = 0

  def initialize(host_storage, task_timeout: 30)
    raise 'Windows OS is not tested and not supported' if (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil

    @is_mac = (/darwin/ =~ RUBY_PLATFORM) != nil
    @task_timeout = task_timeout

    @host_storage = host_storage
    @trash_bag = Hamster::Hash.new

    @selector = NIO::Selector.new
    @scheduler = Rufus::Scheduler.new(:max_work_threads => 1)
    @logger = Logger.new(STDERR)
  end

  def operate(schedule, ping_frequency, tasks_limit)
    @logger.info "Start pinging each #{ping_frequency} secs with max #{tasks_limit / 2} hosts per second"

    @tasks_limit = tasks_limit
    @ping_frequency = ping_frequency
    @schedule = schedule

    @ping_thread  = Thread.new { ping_send_loop } if @ping_thread.nil?
    @reply_thread = Thread.new { reply_receive_loop } if @reply_thread.nil?
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

    @ping_thread.terminate unless @ping_thread.nil?
    @reply_thread.terminate unless @reply_thread.nil?

    @logger.info 'Terminated'
  end

  def ping_send_loop
    @logger.info 'Start ping loop'

    opsecond = 0
    @scheduler.every '1s' do
      @schedule[opsecond].each { |task| ping(task) } unless @schedule[opsecond].nil?

      opsecond += 1
      opsecond %= @ping_frequency

      cleanup
    end

    @scheduler.join
    @logger.info 'Stop ping loop'
  end

  def reply_receive_loop
    @logger.info 'Start reply loop'
    loop do

      unless @selector.nil?
        @selector.wakeup # give a chance to register sockets in pingLoop
        @selector.select { |monitor| monitor.value.call(monitor) }
      end
    end

    @logger.info 'Stop reply loop'
  end

  def ping(task)
    # see https://developer.apple.com/legacy/library/documentation/Darwin/Reference/ManPages/man4/icmp.4.html
    socket = Socket.new(Socket::PF_INET, @is_mac ? Socket::SOCK_DGRAM : Socket::SOCK_RAW, Socket::IPPROTO_ICMP)
    sockaddr = Socket.sockaddr_in(1984, task.host) # port does not matter
    socket.connect(sockaddr)

    msg = [ICMP_ECHO, ICMP_SUBCODE, 0, 42, 1, 'wow such raw so socket'].pack('C2 n3 A*')
    msg[2..3] = [checksum(msg)].pack('n')

    monitor = @selector.register(socket, :r)
    ping_time = Time.now
    monitor.value = proc { on_receive(socket, ping_time, task.host) }
    begin
      socket.sendmsg_nonblock(msg)
    rescue Errno::EBADF
      @logger.error "Failed process #{task} with Errno::EBADF"
    end
    @trash_bag = @trash_bag.put(socket, TaskProgress.new(task))
  end

  def on_receive(socket, ping_time, host)
    rtt = (Time.now - ping_time) * 1000
    @host_storage.save_probe(PingResult.new(host, ping_time, rtt))
    release(socket)
    @trash_bag = @trash_bag.delete socket
  rescue EOFError
    release(socket)
    @trash_bag = @trash_bag.delete socket
  end

  def checksum(msg)
    length    = msg.length
    num_short = length / 2
    check     = 0

    msg.unpack("n#{num_short}").each do |short|
      check += short
    end

    if length % 2 > 0
      check += msg[length - 1, 1].unpack('C').first << 8
    end

    check = (check >> 16) + (check & 0xffff)
    ~((check >> 16) + check) & 0xffff
  end

  def cleanup
    outdated = []
    @trash_bag.each do |socket, task_progress|
      if task_progress.ttl > @task_timeout
        outdated << socket
        release(socket)
      end
    end

    unless outdated.empty?
      @logger.debug "Cleaned #{outdated.size} items: [#{@trash_bag[outdated[0]]} ...], remains: #{@trash_bag.size}"
    end

    @trash_bag = @trash_bag.except(*outdated)

    @trash_bag = cleanup_oldest(@trash_bag, @tasks_limit)

    @trash_bag = @trash_bag.map { |socket, task_progress| [socket, task_progress.hop] }
  end

  def release(socket)
    @selector.deregister socket
    socket.close
  end

  def cleanup_oldest(trash_bag, limit)
    reserve = limit / 2 - trash_bag.size
    if reserve < 0
      flatten =  trash_bag.sort_by { |_, task_progress| task_progress.ttl }.flatten(1)
      outdated_idx = (0...flatten.size).select(&:even?).to_a[reserve..-1]
      outdated = flatten.values_at(*outdated_idx)

      unless outdated.empty?
        @logger.warn "Dropped #{outdated.size} items: [#{@trash_bag[outdated[0]]} ...], remains: #{@trash_bag.size}"
      end

      trash_bag = trash_bag.except(*outdated)
      outdated.each { |socket| release(socket) }
    end

    trash_bag
  end

  private :ping_send_loop, :reply_receive_loop, :ping, :on_receive, :checksum, :cleanup, :release

end