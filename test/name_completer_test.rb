require 'minitest/unit'

require_relative '../lib/name_completer'

class NameCompleterTest < MiniTest::Unit::TestCase
  def test_empty_name_list
    nc = NameCompleter.new :full_names => []
    assert_raises NameCompleter::NotFound do
      nc.lookup("Example Name")
    end
  end

  def test_name_not_in_list
    nc = NameCompleter.new :full_names => ["In List"]
    assert_raises NameCompleter::NotFound do
      nc.lookup("Not")
    end
  end

  def test_first_name_in_list
    nc = NameCompleter.new :full_names => ["Mel Adams", "Joe Bob"]
    assert_equal "Joe Bob", nc.lookup("Joe")
  end

  def test_first_name_in_list_with_different_case
    nc = NameCompleter.new :full_names => ["Mel Adams", "Joe Bob"]
    assert_equal "Joe Bob", nc.lookup("joe")
  end

  def test_more_than_one_match
    nc = NameCompleter.new :full_names => ["Mel Adams", "Mel Bob"]
    assert_raises NameCompleter::Ambiguous do
      nc.lookup("Mel")
    end
  end
end
