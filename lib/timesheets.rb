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
          entry[:start] = date.to_time + 60 * (smin.to_i + (60 * shr.to_i))
          entry[:end]   = date.to_time + 60 * (emin.to_i + (60 * ehr.to_i))
          entries << entry
        elsif line =~ /^(.+)\s+(\d{1,2}):(\d{1,2})[\s-]+(\d{1,2}):(\d{1,2})$/
          entry = { :raw => line }
          _, name, shr, smin, ehr, emin = $~.to_a
          entry[:name] = name
          entry[:start] = current_date.to_time + 60 * (smin.to_i + (60 * shr.to_i))
          entry[:end]   = current_date.to_time + 60 * (emin.to_i + (60 * ehr.to_i))
          entries << entry
        else
          current_name = line
        end
      end
      entries
    end
  end
end
