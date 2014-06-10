require 'date'

module Timesheets
  def self.parse_raw(io, options = {})
    Parser.new.parse_raw(io, options)
  end

  class Parser
    def parse_raw(io, options = {})
      pc = Struct.
        new(:log_io, :entries, :current_date, :current_names).
        new(options.fetch(:log) { NullIO.new }, [], nil, nil)
      while !io.eof? && line = io.readline
        parse_line(line, pc)
      end
      pc.entries
    end

    private

    # Matches a time (e.g. "5:22") and captures hours and minutes ("5" and "22").
    TimeRegexp = /(\d{1,2}):(\d{1,2})/

    # Matches a time range (e.g. "5:22 - 6:33") and captures hours and minutes from both ("5", "22", "6", "33").
    TimeRangeRegexp = /#{TimeRegexp}[\s-]+#{TimeRegexp}/

    # Matches a date (e.g. "9/2"), captures nothing.
    DateRegexp = /[0-9\/-]+/

    def parse_line(line, pc)
      pc.log_io.puts "< #{line}"
      line = line.strip
      if line =~ /^#{DateRegexp}$/
        # Just a date, set the context.
        pc.current_date = parse_date(line)
        pc.log_io.puts "current_date = #{pc.current_date}"
      elsif line =~ /^#{TimeRangeRegexp}$/
        # Just a time range, assume name and date are already set, output entries.
        _, shr, smin, ehr, emin = $~.to_a
        add_entries(pc, line, :times => mktimes(pc.current_date, [shr, smin], [ehr, emin]))
      elsif line =~ /^(#{DateRegexp})\s+#{TimeRangeRegexp}$/
        # Date and time range, assume name is already set, output entries.
        _, date, shr, smin, ehr, emin = $~.to_a
        add_entries(pc, line, :times => mktimes(parse_date(date), [shr, smin], [ehr, emin]))
      elsif line =~ /^(.+)\s+#{TimeRangeRegexp}$/
        # Name and time range, assume date is already set, output entries.
        _, name, shr, smin, ehr, emin = $~.to_a
        add_entries(pc, line, :names => [name], :times => mktimes(pc.current_date, [shr, smin], [ehr, emin]))
      elsif line =~ /.+/
        # Just names. Update the context.
        pc.current_names = line.split(/,/).map(&:strip)
        pc.log_io.puts "current_names = #{pc.current_names.inspect}"
      end
    end

    def add_entries(pc, line, data)
      names = data.fetch(:names, pc.current_names)
      times = data.fetch(:times)
      names.each do |name|
        entry = { :raw => line }
        entry[:name] = name
        entry[:start], entry[:end] = data.fetch(:times)
        log_entry(pc.log_io, entry)
        pc.entries << entry
      end
    end

    def parse_date(date_str)
      Date.parse(date_str)
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
  end

  class NullIO
    def puts(*)
    end
  end
end
