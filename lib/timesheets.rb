require 'date'

module Timesheets
  def self.parse_raw(io)
    Parser.new.parse_raw(io)
  end

  class Parser
    def parse_raw(io)
      entries = []
      current_date = nil
      current_name = nil
      while !io.eof? && line = io.readline
        line = line.strip
        if line =~ /^[0-9\/-]+$/
          current_date = Date.parse(line)
        elsif line =~ /^([0-9\/-]+)\s+(\d{1,2}):(\d{1,2})[\s-]+(\d{1,2}):(\d{1,2})$/
          entry = { :raw => line }
          _, date, shr, smin, ehr, emin = $~.to_a
          date = Date.parse(date)
          entry[:name] = current_name
          entry[:start], entry[:end] = mktimes(date, [shr, smin], [ehr, emin])
          entries << entry
        elsif line =~ /^(.+)\s+(\d{1,2}):(\d{1,2})[\s-]+(\d{1,2}):(\d{1,2})$/
          entry = { :raw => line }
          _, name, shr, smin, ehr, emin = $~.to_a
          entry[:name] = name
          entry[:start], entry[:end] = mktimes(current_date, [shr, smin], [ehr, emin])
          entries << entry
        else
          current_name = line
        end
      end
      entries
    end

    private

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
  end
end
