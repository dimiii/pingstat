require 'logger'

require_relative 'repository/inmemo'
require_relative 'io'
require_relative 'domain'

class PingDaemon
  attr_reader :tasks, :schedule

  def initialize(hostStorage: InMemory.new, pingIO: PingIO.new(hostStorage), pingFrequency: 60, operated: false)
    raise 'Expected number of seconds > 1 as a ping frequency' if pingFrequency < 2

    @hostStorage = hostStorage
    @pingFrequency = pingFrequency # in seconds
    @limitOfTasks, _ = Process.getrlimit(:NOFILE)
    @tasks  = Hash.new   # host -> PingTask
    @schedule = Hash.new # sec -> [PingTask]
    (0...pingFrequency).each {|sec| @schedule[sec] = [] }
    fill

    @pingIO = pingIO
    @pingIO.operate(@schedule, @pingFrequency, @limitOfTasks) if operated
    @logger = Logger.new(STDERR)
  end

  def add(host)
    merge([host])
    @hostStorage.add host
  end

  def delete(host)
    task = @tasks[host]
    return if task.nil?

    @tasks.delete host
    @schedule[task.secOfMin].delete task
    @hostStorage.delete host
  end

  def summary(host, beginPeriod, endPeriod)
    values = @hostStorage.rtt(host, beginPeriod, endPeriod)
    SummaryReport.new(values, beginPeriod, endPeriod, @pingFrequency)
  end

  def terminate
    @pingIO.terminate
    @hostStorage.terminate
  end

  def fill
    hosts = @hostStorage.hosts
    return if hosts.empty?

    chunkSize = hosts.size / @pingFrequency
    chunks = hosts.each_slice(chunkSize).to_a

    (0...chunks.length).each {|sec| merge(chunks[sec]) }
  end

  def merge(hostsToSchedule)
    pingTime, tasks = @schedule.min_by {|_, tasks| tasks.size} # охуенно же: min_by {|tasks| tasks.size} != min_by {|_, tasks| tasks.size}
    tasksToSchedule = hostsToSchedule.map {|host| PingTask.new(host, pingTime)}

    for task in tasksToSchedule do
      @tasks[task.host] = task
    end
    tasks.concat(tasksToSchedule)

    @logger.warn 'Operation in mode exceeding design parameters' if tasks.size > @limitOfTasks / 2
  end

  private :fill, :merge
end