require 'omf_rete/store'

include OMF::Rete

class TestPredicateStore < Test::Unit::TestCase

  def create_store()
    Store.create(0, type: :predicate)
  end

  def test_create_store
    store = create_store()
  end

  def test_add_tuple_to_empty
    store = create_store()
    assert_raise OMF::Rete::Store::UnknownPredicateException do
      store.add :foo, :b, :c
    end
  end

  def test_add_tuple_one_predicate
    store = create_store()
    store.registerPredicate(:foo, 3)
    store.add :foo, :b, :c
  end

  def test_add_tuple_tow_predicates
    store = create_store()
    store.registerPredicate(:foo, 3)
    store.registerPredicate(:goo, 4)
    store.add :foo, :b, :c
    store.add :goo, :b, :c, :d
  end

  def test_find
    tuples = [[:p1, :b, :c1],
              [:p1, :b, :c2],
              [:p2, :f1],
              [:p2, :f2]
             ]

    store = create_store()
    store.registerPredicate(:p1, 3)
    store.registerPredicate(:p2, 2)

    tuples.each {|t| store.addTuple t }

    r = store.find tuples[0]
    assert_equal Set.new([tuples[0]]), r
    r = store.find [:p1, :b, nil]
    assert_equal Set.new([tuples[0], tuples[1]]), r

    r = store.find tuples[2]
    assert_equal Set.new([tuples[2]]), r
    r = store.find [:p2, nil]
    assert_equal Set.new([tuples[2], tuples[3]]), r
  end

  def test_find_tuple_exceptions
    store = create_store()
    assert_raise OMF::Rete::Store::UnknownPredicateException do
      store.find [:p1, nil]
    end
    store.registerPredicate(:p1, 2)
    assert_equal Set.new([]), store.find([:p1, nil])
    assert_raise OMF::Rete::Store::UnknownPredicateException do
      store.find [:p2, nil]
    end
  end

  def test_subscribe_across_multiple_predicates

    plan = [[:p1, :x?, :y?], [:p2, :y?]]
    tuples = [
      [:p1, 3, 4], [:p1, 4, 5], [:p1, 5, 6],
      [:p2, 4], [:p2, 6]
    ]
    store = create_store()
    store.registerPredicate(:p1, 3)
    store.registerPredicate(:p2, 2)
    tuples.each {|t| store.addTuple t }

    resT = Set.new
    result = store.subscribe(:test, plan) do |t|
      resT << t.to_a
    end

    assert_equal Set.new([[3,4], [5,6]]), resT
  end

end



