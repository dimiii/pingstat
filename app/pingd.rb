require 'logger'

require_relative 'repository/inmemo'
require_relative 'io'
require_relative 'domain'

# Base class of application, which manages monitored hosts, schedules ping tasks and delegates their execution.
class PingDaemon
  attr_reader :tasks, :schedule

  def initialize(host_storage: InMemory.new, ping_io: PingIO.new(host_storage), ping_frequency: 60, operated: false)\
    raise 'Expected number of seconds > 1 as a ping frequency' if ping_frequency < 2

    @host_storage = host_storage
    @ping_frequency = ping_frequency # in seconds
    @tasks_lim, _ = Process.getrlimit(:NOFILE)
    @tasks  = {}   # host -> PingTask
    @schedule = {} # sec -> [PingTask]
    (0...ping_frequency).each { |sec| @schedule[sec] = [] }
    fill

    @ping_io = ping_io
    @ping_io.operate(@schedule, @ping_frequency, @tasks_lim) if operated
    @logger = Logger.new(STDERR)
  end

  def add(host)
    merge([host])
    @host_storage.add host
    @logger.info "Added host #{host} to monitoring"
  end

  def delete(host)
    task = @tasks[host]
    return if task.nil?

    @tasks.delete host
    @schedule[task.opsecond].delete task
    @host_storage.delete host
    @logger.info "Delete host #{host} from monitoring"
  end

  def summary(host, begin_period, end_period)
    values = @host_storage.rtt(host, begin_period, end_period)
    SummaryReport.new(values, begin_period, end_period, @ping_frequency)
  end

  def terminate
    @ping_io.terminate
    @host_storage.terminate
  end

  def fill
    hosts = @host_storage.hosts
    return if hosts.empty?

    chunk_size = hosts.size / @ping_frequency
    chunks = hosts.each_slice(chunk_size == 0 ? 1 : chunk_size).to_a

    (0...chunks.length).each {|sec| merge(chunks[sec]) }
  end

  def merge(hosts_to_schedule)
    opsecond, tasks = @schedule.min_by { |_, tasks| tasks.size } # охуенно же: min_by {|tasks| tasks.size} != min_by {|_, tasks| tasks.size}
    tasks_to_schedule = hosts_to_schedule.map { |host| PingTask.new(host, opsecond) }

    tasks_to_schedule.each { |task| @tasks[task.host] = task }
    tasks.concat(tasks_to_schedule)

    @logger.warn 'Operation in mode exceeding design parameters' if tasks.size > @tasks_lim / 2
  end

  private :fill, :merge
end