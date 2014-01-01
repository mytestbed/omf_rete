require 'omf_rete'
require 'omf_rete/store'
require 'omf_rete/indexed_tuple_set'
require 'omf_rete/join_op'
require 'omf_rete/planner/plan_builder'
require 'stringio'

include OMF::Rete
include OMF::Rete::Planner

class TestFilter < Test::Unit::TestCase


  def _test_plan(plan, storeSize, expected = nil, inTuples = nil, outTuples = nil, outPattern = nil)
    store = Store.create(storeSize)
    pb = PlanBuilder.new(plan, store)
    pb.build

#    pb.describe

    resT = []
    result = pb.materialize(outPattern) do |t|
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
    end
    result
  end

  def test_theshold_test
    plan = [
      [:x?],
      OMF::Rete.filter(:x?) do |x|
        x > 2
      end
    ]
    exp = %{\
out: [x?]
  filtering
    processing
}
    inT = [[1], [2], [3], [4]]
    resT = [[3], [4]]
    _test_plan plan, 1, exp, inT, resT
  end

  def test_theshold_test2
    plan = [
      [:x?, :y?],
      OMF::Rete::filter(:x?) do |x|
        x > 2
      end,
      OMF::Rete.filter(:y?) do |y|
        y > 13
      end
    ]
    exp = %{\
out: [x?, y?]
  filtering
    filtering
      processing
}
    inT = [[1, 11], [2, 12], [3, 13], [4, 14]]
    resT = [[4, 14]]
    _test_plan plan, 2, exp, inT, resT
  end
end
