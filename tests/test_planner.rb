require 'omf_rete/store'
require 'omf_rete/indexed_tuple_set'
require 'omf_rete/join_op'
require 'omf_rete/planner/plan_builder'
require 'stringio'

include OMF::Rete
include OMF::Rete::Planner

class TestPlanner < Test::Unit::TestCase
  
  def test_create_plan_builder
    plan = [[:x?, :b, :c]]
    store = Store.create(3)
    pb = PlanBuilder.new(plan, store)
  end
  
  def _test_plan(plan, storeSize, expected = nil, inTuples = nil, outTuples = nil, outPattern = nil)
    store = Store.create(storeSize)

    # with empty store
    resT = []
    result = store.subscribe(:test, plan, outPattern) do |t|
      resT << t.to_a
    end
  
    out = StringIO.new
    #result.describe(out, 0, 0, '|')
    result.describe(out)
    assert_equal(expected, out.string) if expected
    
    if (inTuples)
      
      inTuples.each do |t|
        store.addTuple(t)
      end
      assert_equal(outTuples, resT)
      
      # same test with already full store
      resT2 = []
      result2 = store.subscribe(:test2, plan, outPattern) do |t|
        resT2 << t.to_a
      end
      assert_equal(outTuples, resT2)
    end
  end

  def test_build_simple_plan
    plan = [[:x?, :b, :c]]
    exp = %{\
out: [x?]
  processing
}
    inT = [[:a, :b, :c], [:d, :b, :e]]
    resT = [[:a]]
    _test_plan plan, 3, exp, inT, resT
  end
  
  def test_build_simple_plan_loaded
    plan = [[:x?, :b, :c]]
    exp = %{\
out: [x?]
  processing
}
    inT = [[:a, :b, :c], [:d, :b, :e]]
    resT = [[:a]]
    _test_plan plan, 3, exp, inT, resT
  end

  
  def test_project
    plan = [[:x?, :b, :y?]]
    exp = %{\
out: [y?]
  processing
}
    inT = [[:a, :b, :c], [:d, :b, :e]]
    resT = [[:c], [:e]]
    _test_plan plan, 3, exp, inT, resT, [:y?]
  end
  
  def test_simple_project
    plan = [[:x?, :b, :y?]]
    exp = %{\
out: [y?]
  processing
}
    inT = [[:a, :b, :c], [:d, :b, :e]]
    resT = [[:c], [:e]]
    _test_plan plan, 3, exp, inT, resT, [:y?]
  end
  
  def test_simple_project2
    plan = [[:x?, :b, :y?]]
    exp = %{\
out: [x?]
  processing
}
    inT = [[:a, :b, :c], [:d, :b, :e]]
    resT = [[:a], [:d]]
    _test_plan plan, 3, exp, inT, resT, [:x?]
  end
  
  def test_simple_project3
    plan = [[:x?, :b, :y?]]
    exp = %{\
out: [y?, x?]
  processing
}
    inT = [[:a, :b, :c], [:d, :b, :e]]
    resT = [[:c, :a], [:e, :d]]
    _test_plan plan, 3, exp, inT, resT, [:y?, :x?]
  end

  def test_simple
    plan = [[:x?, :b, :c], [:d, :e, :f]]
    exp = %{\
out: [x?]
  processing
}
    inT = [[:a, :b, :c], [:d, :b, :e]]
    resT = [[:a]]
    _test_plan plan, 3, exp, inT, resT
  end
  
  def test_build_single_join
    plan = [[:x?, :b, :c], [:x?, :b, :d]]    
    exp = %{\
out: [x?]
  join: [x?] => [x?]
    ts: [x?, b, c]  (index: [x?])
    ts: [x?, b, d]  (index: [x?])
}
    inT = [[:a, :b, :c], [:e, :b, :d], [:a, :b, :d]]
    resT = [[:a]]
    _test_plan plan, 3, exp, inT, resT
  end
  
  def test_build_single_join_with_project
    plan = [[:x?, :b, :y?], [:x?, :y?, :d]]    
    exp = %{\
out: [y?]
  join: [x?, y?] => [y?]
    ts: [x?, b, y?]  (index: [x?, y?])
    ts: [x?, y?, d]  (index: [x?, y?])
}
    inT = [[:a, :b, :c], [:e, :b, :d], [:a, :c, :d]]
    resT = [[:c]]
    _test_plan plan, 3, exp, inT, resT, [:y?]
  end

  def test_build_single_join_with_project2
    plan = [[:x?, :b, :y?], [:x?, :y?, :d]]    
    exp = %{\
out: [y?, x?]
  join: [x?, y?] => [x?, y?]
    ts: [x?, b, y?]  (index: [x?, y?])
    ts: [x?, y?, d]  (index: [x?, y?])
}
    inT = [[:a, :b, :c], [:e, :b, :d], [:a, :c, :d]]
    resT = [[:c, :a]]
    _test_plan plan, 3, exp, inT, resT, [:y?, :x?]
  end


  def test_build_two_joins
    plan = [[:x?, :b, :c], 
            [:y?, :d, nil],
            [:x?, :e, :y?]]    
    exp = %{\
out: [x?, y?]
  join: [y?] => [x?, y?]
    ts: [y?, d, *]  (index: [y?])
    ts: [x?, y?]  (index: [y?])
      join: [x?] => [x?, y?]
        ts: [x?, b, c]  (index: [x?])
        ts: [x?, e, y?]  (index: [x?])
}
    inT = [[:x, :b, :c], [:y, :d, :f], [:x, :e, :y]]
    resT = [[:x, :y]]
    _test_plan plan, 3, exp, inT, resT

  end

  def test_build_three_joins
    plan = [[:x?, :a, :b], 
            [:y?, :c, :d],
            [:x?, :e, :z?],
            [:z?, :f, :y?]]    
    exp = %{\
out: [x?, y?, z?]
  join: [z?] => [x?, y?, z?]
    ts: [x?, z?]  (index: [z?])
      join: [x?] => [x?, z?]
        ts: [x?, a, b]  (index: [x?])
        ts: [x?, e, z?]  (index: [x?])
    ts: [y?, z?]  (index: [z?])
      join: [y?] => [y?, z?]
        ts: [y?, c, d]  (index: [y?])
        ts: [z?, f, y?]  (index: [y?])
}
    inT = [[:x, :a, :b], [:y, :c, :d], [:x, :e, :z], [:z, :f, :y]]
    resT = [[:x, :y, :z]]
    _test_plan plan, 3, exp, inT, resT
  end
  

  def test_siblings
    store = Store.create(3)    
    store.addTuple([:a, :hasParent, :p])
    store.addTuple([:b, :hasParent, :p])

    resT = Set.new
    store.subscribe(:r1, [[:x?, :sibling_of, :y?]]) do |t|
      resT << t.to_a
    end
    assert_equal(Set.new, resT)
    
    subscription = [
      [:x?, :hasParent, :p?], 
      [:y?, :hasParent, :p?],
      OMF::Rete.differ(:x?, :y?) 
    ]
    store.subscribe(:r2, subscription, [:x?, :y?]) do |t|
      store.addTuple([t[:x?], :sibling_of, t[:y?]])
    end

    assert_equal(Set.new([[:b, :a], [:a, :b]]), resT)
    
  end
  
  def test_remove
    store = Store.create(2)

    # with empty store
    resT = []
    plan = [[nil, :x?], [:x?, nil]]
    result = store.subscribe(:test, plan) do |t, action|
      #puts "#{action}: #{t.to_a.inspect}"
      action == :add ? resT << t.to_a : resT.delete(t.to_a)
    end
    #result.describe()
    store.add(:a, :b)    
    store.add(:b, :c)
    assert_equal([[:b]], resT)

    store.remove(:a, :b)  
    assert_equal([], resT)
    
    store.add(:a, :b)    
    store.add(:d, :b)    
    assert_equal([[:b]], resT)
    
    store.remove(:a, :b)    
    assert_equal([[:b]], resT)    

    store.remove(:d, :b)    
    assert_equal([], resT)     
    #store.addTuple(:a, :b)    
  end  
end