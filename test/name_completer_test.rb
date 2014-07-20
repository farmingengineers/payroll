require 'minitest/unit'

require_relative '../lib/name_completer'

class NameCompleterTest < MiniTest::Unit::TestCase
  def test_empty_name_list
    nc = NameCompleter.new :full_names => []
    assert_equal "Example Name", nc.lookup("Example Name")
  end

  def test_name_not_in_list
    nc = NameCompleter.new :full_names => ["In List"]
    assert_equal "Not", nc.lookup("Not")
  end

  def test_first_name_in_list
    nc = NameCompleter.new :full_names => ["Mel Adams", "Joe Bob"]
    assert_equal "Joe Bob", nc.lookup("Joe")
  end
end
