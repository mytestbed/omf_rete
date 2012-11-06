require 'omf_rete/join_op'

include OMF::Rete

class TestJoinOP < Test::Unit::TestCase
  def test_create_joinop
    l = IndexedTupleSet.new([:x?], [:x?])
    r = IndexedTupleSet.new([:x?], [:x?])
    out = IndexedTupleSet.new([:x?], [:x?])
    JoinOP.new(l, r, out)
  end
  
  # [:a :x?], [?x :c]
  #
  def test_join1
    t1 = ['a', 'b']
    t2 = ['b', 'd']
    l = OMF::Rete::IndexedTupleSet.new([:a?, :x?], [:x?])
    r = OMF::Rete::IndexedTupleSet.new([:x?, :b?], [:x?])
    out = IndexedTupleSet.new([:a?, :b?], [:a?])
    JoinOP.new(l, r, out)
    l.addTuple(t1)
    r.addTuple(t2)
    assert_equal [[t1[0], t2[1]]], out.to_a
  end
  
  def test_three_result_set
    t1 = ['y', 'z', 'b', 'x']
    t2 = ['c', 'd', 'x', 'b']
    l = OMF::Rete::IndexedTupleSet.new([:y?, :z?, :b, :x?], [:x?])
    r = OMF::Rete::IndexedTupleSet.new([:c, :d, :x?, :b], [:x?])
    out = IndexedTupleSet.new([:x?, :y?, :z?], [:x?])
    JoinOP.new(l, r, out)
    l.addTuple(t1)
    r.addTuple(t2)
    assert_equal [['x', 'y', 'z']], out.to_a
  end
  
  def test_join2
    t1 = ['y', 'z', 'b', 'x']
    t2 = ['c', 'd', 'x', 'y']
    l = OMF::Rete::IndexedTupleSet.new([:y?, :z?, :b, :x?], [:x?, :y?])
    r = OMF::Rete::IndexedTupleSet.new([:c, :d, :x?, :y?], [:x?, :y?])
    out = IndexedTupleSet.new([:x?, :y?, :z?], [:x?])
    JoinOP.new(l, r, out)
    l.addTuple(t1)
    r.addTuple(t2)
    assert_equal [['x', 'y', 'z']], out.to_a
  end
end
