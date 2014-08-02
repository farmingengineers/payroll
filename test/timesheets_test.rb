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

  def test_shared_shifts
    timesheet = <<TS
9/3
Joe Bob, Mel Adams
7:55 - 9:01
9:30 - 13:30
TS
    assert_equal [
      {:name => "Joe Bob", :start => T_3Sep_7_55, :end => T_3Sep_9_01},
      {:name => "Mel Adams", :start => T_3Sep_7_55, :end => T_3Sep_9_01},
      {:name => "Joe Bob", :start => T_3Sep_9_30, :end => T_3Sep_13_30},
      {:name => "Mel Adams", :start => T_3Sep_9_30, :end => T_3Sep_13_30},
    ], parse(timesheet)
  end

  def test_shared_shift
    timesheet = <<TS
9/3
Joe Bob, Mel Adams 7:55 - 9:01
TS
    assert_equal [
      {:name => "Joe Bob", :start => T_3Sep_7_55, :end => T_3Sep_9_01},
      {:name => "Mel Adams", :start => T_3Sep_7_55, :end => T_3Sep_9_01},
    ], parse(timesheet)
  end

  def test_single_digit_times
    timesheet = <<TS
9/2
Joe Bob, Mel Adams
7 - 7:52
8:19 - 9
10 - 11
1 - 2

9/3
Joe Bob 7 - 7:55
Mel Adams 8:01 - 9
Joe Bob 10 - 12
Mel Adams 1 - 2
TS
    assert_equal [
      {:name => "Joe Bob", :start => T_2Sep_7_00, :end => T_2Sep_7_52},
      {:name => "Mel Adams", :start => T_2Sep_7_00, :end => T_2Sep_7_52},
      {:name => "Joe Bob", :start => T_2Sep_8_19, :end => T_2Sep_9_00},
      {:name => "Mel Adams", :start => T_2Sep_8_19, :end => T_2Sep_9_00},
      {:name => "Joe Bob", :start => T_2Sep_10_00, :end => T_2Sep_11_00},
      {:name => "Mel Adams", :start => T_2Sep_10_00, :end => T_2Sep_11_00},
      {:name => "Joe Bob", :start => T_2Sep_1_00, :end => T_2Sep_2_00},
      {:name => "Mel Adams", :start => T_2Sep_1_00, :end => T_2Sep_2_00},

      {:name => "Joe Bob", :start => T_3Sep_7_00, :end => T_3Sep_7_55},
      {:name => "Mel Adams", :start => T_3Sep_8_01, :end => T_3Sep_9_00},
      {:name => "Joe Bob", :start => T_3Sep_10_00, :end => T_3Sep_12_00},
      {:name => "Mel Adams", :start => T_3Sep_1_00, :end => T_3Sep_2_00},
    ], parse(timesheet)
  end

  Year = Time.now.year
  T_2Sep_7_00 = Time.local(Year, "sep", 2, 7, 00)
  T_2Sep_7_52 = Time.local(Year, "sep", 2, 7, 52)
  T_2Sep_8_19 = Time.local(Year, "sep", 2, 8, 19)
  T_2Sep_9_00 = Time.local(Year, "sep", 2, 9, 00)
  T_2Sep_10_00 = Time.local(Year, "sep", 2, 10, 00)
  T_2Sep_11_00 = Time.local(Year, "sep", 2, 11, 00)
  T_2Sep_1_00 = Time.local(Year, "sep", 2, 1, 00)
  T_2Sep_2_00 = Time.local(Year, "sep", 2, 2, 00)
  T_2Sep_13_19 = Time.local(Year, "sep", 2, 13, 19)

  T_3Sep_7_00 = Time.local(Year, "sep", 3, 7, 00)
  T_3Sep_7_55 = Time.local(Year, "sep", 3, 7, 55)
  T_3Sep_8_01 = Time.local(Year, "sep", 3, 8, 01)
  T_3Sep_9_00 = Time.local(Year, "sep", 3, 9, 00)
  T_3Sep_9_01 = Time.local(Year, "sep", 3, 9, 01)
  T_3Sep_9_30 = Time.local(Year, "sep", 3, 9, 30)
  T_3Sep_10_00 = Time.local(Year, "sep", 3, 10, 00)
  T_3Sep_12_00 = Time.local(Year, "sep", 3, 12, 00)
  T_3Sep_13_30 = Time.local(Year, "sep", 3, 13, 30)
  T_3Sep_1_00 = Time.local(Year, "sep", 3, 1, 00)
  T_3Sep_2_00 = Time.local(Year, "sep", 3, 2, 00)

  private

  def parse(timesheet)
    require 'stringio'
    Timesheets.parse_raw(StringIO.new(timesheet)).map { |x| {:name => x[:name], :start => x[:start], :end => x[:end]} }
  end

  require 'pp'
  def mu_pp(obj)
    obj.pretty_inspect
  end
end
