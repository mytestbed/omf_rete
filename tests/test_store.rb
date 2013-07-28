require 'omf_rete/store'

include OMF::Rete

class TestStore < Test::Unit::TestCase
  def test_create_store
    store = Store.create(3)
  end
  
  def test_add_tuple
    store = Store.create(3)
    store.addTuple [:a, :b, :c]
  end
  
  def test_add_tuple2
    store = Store.create(3)
    store.add :a, :b, :c
  end

  def test_find
    t1 = [:a, :b, :c]
    t2 = [t1[0], t1[1], :d] 
    store = Store.create(3)
    
    store.addTuple t1 
    store.addTuple t2
    
    r = store.find t1
    assert_equal r, Set.new([t1])
    
    r = store.find [t1[0], t1[1], nil]
    assert_equal r, Set.new([t1, t2])

    r = store.find [t1[0], nil, t1[2]]
    assert_equal r, Set.new([t1])
    
    r = store.find [t1[0], :_, t1[2]]
    assert_equal r, Set.new([t1])

    r = store.find [nil, nil, nil]
    assert_equal r, Set.new([t1, t2])

    r = store.find [:_, :_, :_]
    assert_equal r, Set.new([t1, t2])
    
    r = store.find [:b, nil, nil]
    assert_equal r, Set.new()

    r = store.find [:b, :_, :_]
    assert_equal r, Set.new()

  end

  def test_find_tuple2
    store = Store.create(3)
    store.add :a, :b, :c
    
    t1 = [:a, :b, :c]
    r = store.find t1
    assert_equal r, Set.new([t1])
  end

  def test_tset_init
    t1 = [:a, :b, :c]
    store = Store.create(3)
    store.addTuple t1 

    ts = MockTSet.new
    store.registerTSet(ts, t1)
    assert_equal ts.tuples, [t1]
  end

  def test_tset_add_full
    t1 = [:a, :b, :c]

    store = Store.create(3)

    ts = MockTSet.new
    store.registerTSet(ts, t1)
    assert_equal nil, ts.tuples

    store.addTuple t1 
    assert_equal [t1], ts.tuples
  end

  def test_tset_add_last_nil
    t1 = [:a, :b, :c]

    store = Store.create(3)

    ts = MockTSet.new
    store.registerTSet(ts, [t1[0], t1[1], nil])
    assert_equal nil, ts.tuples

    store.addTuple t1 
    assert_equal [t1], ts.tuples
  end

  def test_tset_add_second_nil
    t1 = [:a, :b, :c]

    store = Store.create(3)

    ts = MockTSet.new
    store.registerTSet(ts, [t1[0], nil, t1[2]])
    assert_equal nil, ts.tuples

    store.addTuple t1 
    assert_equal [t1], ts.tuples
  end
  
  def test_tset_add_first_nil
    t1 = [:a, :b, :c]

    store = Store.create(3)

    ts = MockTSet.new
    store.registerTSet(ts, [nil, t1[1], t1[2]])
    assert_equal nil, ts.tuples

    store.addTuple t1 
    assert_equal [t1], ts.tuples
  end
  
  def test_tset_add_multiple_nil
    t1 = [:a, :b, :c]

    store = Store.create(3)

    ts = MockTSet.new
    store.registerTSet(ts, [nil, t1[1], nil])
    assert_equal nil, ts.tuples

    store.addTuple t1 
    assert_equal [t1], ts.tuples
    
    t2 = [:d, :b, :f]
    store.addTuple t2 
    assert_equal [t1, t2], ts.tuples

    t3 = [:g, :h, :j]
    store.addTuple t3
    assert_equal [t1, t2], ts.tuples
  end

  def test_tset_remove
    t1 = [:a, :b, :c]

    store = Store.create(3)

    ts = MockTSet.new
    store.registerTSet(ts, t1)

    store.addTuple t1
    store.removeTuple t1 
    assert_equal [], ts.tuples
  end
  
  def test_tset_remove_multiple_nil
    t1 = [:a, :b, :c]

    store = Store.create(3)

    ts = MockTSet.new
    store.registerTSet(ts, [nil, t1[1], nil])
    store.addTuple t1 

    t2 = [:d, :b, :f]
    store.addTuple t2 

    store.removeTuple t1
    assert_equal [t2], ts.tuples
    
    r = store.find t1
    assert_equal r, Set.new()
    r = store.find [:a, nil, nil]
    assert_equal r, Set.new()
    
    t3 = [:g, :h, :j]
    store.addTuple t3
    assert_equal [t2], ts.tuples
    
    store.removeTuple t2
    assert_equal [], ts.tuples
    
  end
  




#          assert_instance_of OEDLMissingArgumentException, ex
#          assert_equal :name, ex.argName
end

class MockTSet
  attr_reader :tuples
  
  def addTuple(t)
    (@tuples ||= []) << t
  end
  
  def removeTuple(t)
    @tuples.delete t
  end

  
  def reset()
    @tuples = nil
  end
end # MockTSet


