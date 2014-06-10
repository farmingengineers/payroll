require 'date'

module Timesheets
  def self.parse_raw(io, options = {})
    Parser.new.parse_raw(io, options)
  end

  class Parser
    def parse_raw(io, options = {})
      pc = Struct.
        new(:log_io, :entries, :current_date, :current_name).
        new(options.fetch(:log) { NullIO.new }, [], nil, nil)
      while !io.eof? && line = io.readline
        parse_line(line, pc)
      end
      pc.entries
    end

    private

    def parse_line(line, pc)
      pc.log_io.puts "< #{line}"
      line = line.strip
      if line =~ /^[0-9\/-]+$/
        pc.current_date = Date.parse(line)
      elsif line =~ /^([0-9\/-]+)\s+(\d{1,2}):(\d{1,2})[\s-]+(\d{1,2}):(\d{1,2})$/
        entry = { :raw => line }
        _, date, shr, smin, ehr, emin = $~.to_a
        date = Date.parse(date)
        entry[:name] = pc.current_name
        entry[:start], entry[:end] = mktimes(date, [shr, smin], [ehr, emin])
        log_entry(pc.log_io, entry)
        pc.entries << entry
      elsif line =~ /^(.+)\s+(\d{1,2}):(\d{1,2})[\s-]+(\d{1,2}):(\d{1,2})$/
        entry = { :raw => line }
        _, name, shr, smin, ehr, emin = $~.to_a
        entry[:name] = name
        entry[:start], entry[:end] = mktimes(pc.current_date, [shr, smin], [ehr, emin])
        log_entry(pc.log_io, entry)
        pc.entries << entry
      else
        pc.current_name = line
      end
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
