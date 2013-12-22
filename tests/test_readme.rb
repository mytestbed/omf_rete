require 'omf_rete/store'

#include OMF::Rete


#
# Test the eamples in teh README file
#
class TestReadme < Test::Unit::TestCase
  attr_reader :eng

  def setup
    @eng = OMF::Rete.create_engine(tuple_length: 3)

    @res = []
  end

  def puts(msg)
    @res << msg
  end

  def assert_puts(expected)
    assert_equal expected, @res
  end

  def test_example1
    eng = OMF::Rete.create_engine(tuple_length: 3)
    eng.add_fact('myFridge', 'contains', 'milk')
  end

  def test_example2
    eng.add_rule(:report_problem, [
      ['myFridge', 'status', 'broken']
    ]) do |m|
      puts "My fridge is broken"
    end
    eng.add_fact('myFridge', 'status', 'ok')
    eng.add_fact('myFridge', 'status', 'broken')

    assert_puts ["My fridge is broken"]
  end

  def test_example3
    eng.add_fact('myFridge', 'contains', 'milk')
    eng.subscribe(:save_milk, [
      [:fridge?, 'status', 'broken'],
      [:fridge?, 'contains', 'milk'],
    ]) do |m|
      puts "Save the milk from #{m.fridge?}"
    end
    eng.add_fact('myFridge', 'status', 'broken')

    assert_puts ["Save the milk from myFridge"]
  end

  def test_example4
    eng.subscribe(:something_broken, [
      [nil, 'status', 'broken']
    ]) do |m|
      puts "Something is broken"
    end
    eng.add_fact('myFridge', 'status', 'broken')

    assert_puts ["Something is broken"]
  end
end
