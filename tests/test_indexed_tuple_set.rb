require 'omf_rete/indexed_tuple_set'

include OMF::Rete

class TestIndexedTupleSet < Test::Unit::TestCase
  def test_create_tset
    IndexedTupleSet.new([:x?], [:x?])
    IndexedTupleSet.new([:x?, nil, :y?], [:x?])    
  end
  
  def test_add_tuple
    t = [:a, :b, :c]
    ts = IndexedTupleSet.new([:x?, nil, nil], [:x?])
    ts.addTuple(t)
    assert_equal [t], ts.to_a
  end
  
  def test_index0
    t = [:a, :b, :c]
    ts = IndexedTupleSet.new([:x?, nil, nil], [:x?])
    ts.addTuple(t)
    assert_equal [t], ts[[t[0]]].to_a
  end

  
  def test_add_tuple_def_ts2
    t1 = ['a', 'b', 'c']  # use strings as we need to sort tuple arrays
    t2 = ['a', 'b', 'd']
    ts = IndexedTupleSet.new([:x?], [:x?])
    ts.addTuple(t1)
    ts.addTuple(t2)    
    assert_equal [t1, t2].sort, ts.to_a.sort
  end
  
  def test_index_pattern
    t = [:a, :b, :c]
    ts = IndexedTupleSet.new([:x?, :y?, :z?], [:y?, :x?])
    ts.addTuple(t)
    assert_equal [t], ts[[t[1], t[0]]].to_a
  end

  def test_add_tuple_each
    t1 = ['a', 'b', 'c']  # use strings as we need to sort tuple arrays
    t2 = ['a', 'b', 'd']
    ts = IndexedTupleSet.new([:x?, :y?, :z?], [:x?])
    ts.addTuple(t1)
    a = []
    ts.on_add do |t|
      a << t
    end
    assert_equal [t1], a
    ts.addTuple(t2)    
    assert_equal [t1, t2], a
  end
     


end
