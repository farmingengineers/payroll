require 'minitest/unit'

require_relative '../lib/timesheets'

class TimesheetParseTest < MiniTest::Unit::TestCase
  def test_date_first_timesheet
    timesheet = <<TS
9/2
Joe Bob 7:52 8:19
9/3
Joe Bob 7:55-9:30
Mel Adams 8:01 9:01
TS
    assert_equal [
      {:name => 'Joe Bob', :start => T_2Sep_7_52, :end => T_2Sep_8_19},
      {:name => 'Joe Bob', :start => T_3Sep_7_55, :end => T_3Sep_9_30},
      {:name => 'Mel Adams', :start => T_3Sep_8_01, :end => T_3Sep_9_01},
    ], parse(timesheet)
  end

  def test_name_first_timesheet
    timesheet = <<TS
Joe Bob
9/2 7:52-8:19
9/3 7:55 9:30
Mel Adams
9/3 8:01 9:01
TS
    assert_equal [
      {:name => 'Joe Bob', :start => T_2Sep_7_52, :end => T_2Sep_8_19},
      {:name => 'Joe Bob', :start => T_3Sep_7_55, :end => T_3Sep_9_30},
      {:name => 'Mel Adams', :start => T_3Sep_8_01, :end => T_3Sep_9_01},
    ], parse(timesheet)
  end

  def test_parse_24_and_12_hour_clock
    timesheet = <<TS
Joe Bob
9/2 7:52-1:19
9/3 7:55 13:30
TS
    assert_equal [
      {:name => 'Joe Bob', :start => T_2Sep_7_52, :end => T_2Sep_13_19},
      {:name => 'Joe Bob', :start => T_3Sep_7_55, :end => T_3Sep_13_30},
    ], parse(timesheet)
  end

  Year = Time.now.year
  T_2Sep_7_52 = Time.local(Year, "sep", 2, 7, 52)
  T_2Sep_8_19 = Time.local(Year, "sep", 2, 8, 19)
  T_2Sep_13_19 = Time.local(Year, "sep", 2, 13, 19)
  T_3Sep_7_55 = Time.local(Year, "sep", 3, 7, 55)
  T_3Sep_9_30 = Time.local(Year, "sep", 3, 9, 30)
  T_3Sep_13_30 = Time.local(Year, "sep", 3, 13, 30)
  T_3Sep_8_01 = Time.local(Year, "sep", 3, 8, 01)
  T_3Sep_9_01 = Time.local(Year, "sep", 3, 9, 01)

  private

  def parse(timesheet)
    require 'stringio'
    Timesheets.parse_raw(StringIO.new(timesheet)).map { |x| {:name => x[:name], :start => x[:start], :end => x[:end]} }
  end
end
