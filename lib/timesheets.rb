require 'date'

module Timesheets
  def self.parse_raw(io, options = {})
    Parser.new.parse_raw(io, options)
  end

  class Parser
    def parse_raw(io, options = {})
      result = Struct.new(:entries, :tasks).new([], [])
      pc = Struct.
        new(:log_io, :name_completer, :result, :current_date, :current_names, :line_number, :path).
        new(options.fetch(:log) { NullIO.new }, options.fetch(:names) { NullNames.new }, result, nil, nil, 0, nil)
      pc.path = io.path if io.respond_to?(:path)
      while !io.eof? && line = io.readline
        pc.line_number += 1
        parse_line(line, pc)
      end
      pc.result
    rescue Object => e
      e.extend HasParserContext
      e.parser_context = pc
      raise
    end

    private

    # Matches a time (e.g. "5:22") and captures hours and minutes ("5" and "22").
    TimeRegexp = /(\d{1,2})(?::(\d{1,2}))?/

    # Matches a time range (e.g. "5:22 - 6:33") and captures hours and minutes from both ("5", "22", "6", "33").
    TimeRangeRegexp = /#{TimeRegexp}[\s-]+#{TimeRegexp}/

    # Matches a date (e.g. "9/2"), captures nothing.
    DateRegexp = /[0-9\/-]+/

    def parse_line(line, pc)
      pc.log_io.puts "< #{line}"
      line, *tasks = line.split(/\s*\*\s*/).map(&:strip)
      new_entries = []
      case line
      when /^#{DateRegexp}$/
        # Just a date, set the context.
        pc.current_date = parse_date(line)
        pc.log_io.puts "current_date = #{pc.current_date}"
      when /^#{TimeRangeRegexp}$/
        # Just a time range, assume name and date are already set, output entries.
        _, shr, smin, ehr, emin = $~.to_a
        new_entries = add_entries(pc, line, :times => mktimes(pc.current_date, [shr, smin], [ehr, emin]))
      when /^(#{DateRegexp})\s+#{TimeRangeRegexp}$/
        # Date and time range, assume name is already set, output entries.
        _, date, shr, smin, ehr, emin = $~.to_a
        new_entries = add_entries(pc, line, :times => mktimes(parse_date(date), [shr, smin], [ehr, emin]))
      when /^(.+)\s+#{TimeRangeRegexp}$/
        # Name and time range, assume date is already set, output entries.
        _, names, shr, smin, ehr, emin = $~.to_a
        new_entries = add_entries(pc, line, :names => split_names(pc, names), :times => mktimes(pc.current_date, [shr, smin], [ehr, emin]))
      when /.+/
        # Just names. Update the context.
        pc.current_names = split_names(pc, line)
        pc.log_io.puts "current_names = #{pc.current_names.inspect}"
      when /\A\s*\z/
        # nothing
      else
        raise "Unparseable #{line.inspect}"
      end
      add_tasks(pc, tasks, new_entries)
    end

    def add_entries(pc, line, data)
      names = data.fetch(:names, pc.current_names)
      times = data.fetch(:times)
      names.map do |name|
        entry = { :raw => line }
        entry[:name] = name
        entry[:start], entry[:end] = data.fetch(:times)
        log_entry(pc.log_io, entry)
        pc.result.entries << entry
        entry
      end
    end

    def split_names(pc, str)
      str.split(",").map(&:strip).map { |name| pc.name_completer.lookup(name) or raise "Line #{pc.line_number}: Didn't recognize #{name.inspect}" }
    end

    def add_tasks(pc, raw_tasks, entries)
      return [] unless raw_tasks.any?
      entries_hours = entries.inject(0.0) { |sum, entry| sum + (entry[:end] - entry[:start]) / 3600.0 }
      task_date = entries.any? ? entries.first[:start].to_date : pc.current_date
      tasks = raw_tasks.map do |line|
        task = {}
        words = []
        line.split(/\s+/).each do |word|
          case word
          when /(\d+)min/
            task[:hours] = $1.to_f / 60.0
          when /(\d+)hr/, /(\d+)h/
            task[:hours] = $1.to_f
          else
            words << word
          end
        end
        entries_hours -= task[:hours].to_f
        task.update \
          :date => task_date,
          :name => words.join(" ")
      end
      if entries_hours > 0
        no_hours = tasks.select { |task| task[:hours].nil? }
        hours_per = entries_hours / no_hours.size
        no_hours.each { |task| task[:hours] = hours_per }
      end
      tasks.each do |task|
        pc.result.tasks << task
        log_task(pc.log_io, task)
      end
    end

    def parse_date(date_str)
      m, d, y = date_str.split("/", 3)
      y ||= Time.now.year
      Date.new y.to_i, m.to_i, d.to_i
    end

    def mktimes(date, raw_start, raw_end)
      start_time = mktime(date, *raw_start)
      end_time = mktime(date, *raw_end)
      if end_time < start_time
        end_time += 12 * 60 * 60
      end
      [start_time, end_time]
    end

    def mktime(date, hr, min)
      date.to_time + 60 * (min.to_i + (60 * hr.to_i))
    end

    def log_entry(log_io, entry)
      entry = entry.dup
      entry.delete(:raw)
      log_io.puts entry.inspect
    end

    def log_task(log_io, task)
      task = task.dup
      task[:date] = task[:date].to_s
      log_io.puts(task.inspect)
    end
  end

  class NullIO
    def puts(*)
    end
  end

  class NullNames
    def lookup(s)
      s
    end
  end

  module HasParserContext
    attr_accessor :parser_context

    def message
      if parser_context && parser_context.line_number
        "at input #{parser_context.path ? (parser_context.path + ":") : "line "}#{parser_context.line_number}: #{super}"
      else
        super
      end
    end
  end
end
