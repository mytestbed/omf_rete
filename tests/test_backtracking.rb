
class TestBacktracking < Test::Unit::TestCase
  
  def _test_plan(plan, storeSize, inTuples = nil, outTuples = nil, outPattern = nil, &requestProc)
    store = Store.create(storeSize)
    store.on_query &requestProc # proc to call if store gets a request for a tuple which doesn't exist
    pb = PlanBuilder.new(plan, store, :backtracking => true)
    pb.build

#    pb.describe

    resT = []
    result = pb.materialize(outPattern) do |t|
      resT << t
    end
      
    if (inTuples)
      inTuples.each do |t|
        store.addTuple(t)
      end
      assert_equal(outTuples, resT)
    end
    result
  end
  
  def x_test_request_one
    plan = [
      [:user?, :do, :action?], 
      [:pi, :endorses, :user?]
    ]
    inT = [[:u1, :do, :start]]
    resT = inT
    _test_plan plan, 3, inT, resT do |*t|
      puts ">>>>>>>>>>>"
    end
    
  end  
  
  def test_dummy
    assert_equal(1, 1)
  end
end # TestBacktracking