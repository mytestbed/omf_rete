require 'omf_rete/store'

include OMF::Rete

class TestObjectStore < Test::Unit::TestCase

  class Obj
    attr_accessor :a, :b

    def initialize(a, b = nil)
      self.a = a; self.b = b
    end
  end

  class User
    attr_accessor :name

    def initialize(name)
      self.name = name
    end
  end

  def create_store(opts = {})
    Store.create(0, opts.merge(type: :object))
  end

  def test_create_store
    store = create_store()
  end

  def test_add_tuple_to_empty
    store = create_store()
    assert_raise OMF::Rete::Store::NotImplementedException do
      store.add :a
    end
  end

  def test_find_single
    store = create_store()
    store.representObject(Obj.new(1))
    assert_equal Set.new([[:a, 1]]), store.find([:a, nil])
  end

  def test_find_single2
    store = create_store(name: :p)
    store.representObject(Obj.new(1))
    assert_equal Set.new([[:p, :a, 1]]), store.find([:p, :a, nil])
  end

  def test_find_enumerable
    store = create_store()
    store.representObject(Obj.new([1,2]))
    assert_equal Set.new([[:a, 1], [:a, 2]]), store.find([:a, nil])
  end

  def test_find_validate
    store = create_store()
    store.representObject(Obj.new(1))
    assert_equal Set.new([[:a, 1]]), store.find([:a, 1])
    assert_equal Set.new([]), store.find([:a, 2])
  end

  def test_find_validate_enumerable
    store = create_store()
    store.representObject(Obj.new([1,2]))
    assert_equal Set.new([[:a, 1]]), store.find([:a, 1])
  end

  def test_tset
    store = create_store()
    store.representObject(Obj.new(1))
    tset = store.createTSet([:a, :x?], [:x?])
    assert_equal Set.new([[:a, 1]]), tset.to_set
  end

  def test_tset2
    store = create_store(name: :p)
    store.representObject(Obj.new(1))
    tset = store.createTSet([:p, :a, :x?], [:x?])
    assert_equal Set.new([[:p, :a, 1]]), tset.to_set
  end

  def test_change_object_tset
    store = create_store()
    store.representObject(Obj.new(1))
    tset = store.createTSet([:a, :x?], [:x?])
    store.representObject(Obj.new(2))
    assert_equal Set.new([[:a, 2]]), tset.to_set
  end

  def test_change_object_subscribe

    store = create_store()
    store.representObject(Obj.new(1))

    plan = [[:a, :x?]]

    resT = Set.new
    actionSet = Set.new
    result = store.subscribe(:test, plan) do |t, a|
      (resT << t.to_a) if a == :add
      actionSet << a
    end
    assert_equal Set.new([[1]]), resT
    assert_equal Set.new([:add]), actionSet

    # Now lets change the object
    resT.clear; actionSet.clear
    store.representObject(Obj.new(2))
    assert_equal Set.new([[2]]), resT
    assert_equal Set.new([:cleared, :add]), actionSet
  end

  def test_change_object_subscribe_two_stores

    store = Store.create(0, type: :predicate)

    as_store = store.registerPredicate(:as, 3)
    store.add :as, :userA, :ok

    msg_store = Store.create(0, type: :object, name: :m)
    store.registerPredicateStore(:m, msg_store)

    plan = [[:m, :name, :n?], [:as, :n?, :y?]]

    resT = Set.new
    actionSet = Set.new
    result = store.subscribe(:test, plan) do |t, a|
      (resT << t.to_a) if a == :add
      actionSet << a
    end

    msg_store.representObject(User.new(:userA))

    assert_equal Set.new([[:m, :name, :userA]]), store.find([:m, :name, nil])
    assert_equal Set.new([[:as, :userA, :ok]]), store.find([:as, nil, nil])
    assert_equal Set.new([[:userA, :ok]]), resT
    assert_equal Set.new([:cleared, :add]), actionSet

    # Now lets change the object
    resT.clear; actionSet.clear
    msg_store.representObject(User.new(:userB))
    assert_equal Set.new(), resT
    assert_equal Set.new([:cleared]), actionSet
  end


  # def test_subscribe_across_multiple_predicates
#
    # plan = [[:p1, :x?, :y?], [:p2, :y?]]
    # tuples = [
      # [:p1, 3, 4], [:p1, 4, 5], [:p1, 5, 6],
      # [:p2, 4], [:p2, 6]
    # ]
    # store = create_store()
    # store.registerPredicate(:p1, 3)
    # store.registerPredicate(:p2, 2)
    # tuples.each {|t| store.addTuple t }
#
    # resT = Set.new
    # result = store.subscribe(:test, plan) do |t|
      # resT << t.to_a
    # end
#
    # assert_equal Set.new([[3,4], [5,6]]), resT
  # end

  # def test_add_tuple_one_predicate
    # store = create_store()
    # store.registerPredicate(:foo, 3)
    # store.add :foo, :b, :c
  # end
#
  # def test_add_tuple_tow_predicates
    # store = create_store()
    # store.registerPredicate(:foo, 3)
    # store.registerPredicate(:goo, 4)
    # store.add :foo, :b, :c
    # store.add :goo, :b, :c, :d
  # end
#
  # def test_find
    # tuples = [[:p1, :b, :c1],
              # [:p1, :b, :c2],
              # [:p2, :f1],
              # [:p2, :f2]
             # ]
#
    # store = create_store()
    # store.registerPredicate(:p1, 3)
    # store.registerPredicate(:p2, 2)
#
    # tuples.each {|t| store.addTuple t }
#
    # r = store.find tuples[0]
    # assert_equal Set.new([tuples[0]]), r
    # r = store.find [:p1, :b, nil]
    # assert_equal Set.new([tuples[0], tuples[1]]), r
#
    # r = store.find tuples[2]
    # assert_equal Set.new([tuples[2]]), r
    # r = store.find [:p2, nil]
    # assert_equal Set.new([tuples[2], tuples[3]]), r
  # end
#
  # def test_find_tuple_exceptions
    # store = create_store()
    # assert_raise OMF::Rete::Store::UnknownPredicateException do
      # store.find [:p1, nil]
    # end
    # store.registerPredicate(:p1, 2)
    # assert_equal Set.new([]), store.find([:p1, nil])
    # assert_raise OMF::Rete::Store::UnknownPredicateException do
      # store.find [:p2, nil]
    # end
  # end
#
  # def test_subscribe_across_multiple_predicates
#
    # plan = [[:p1, :x?, :y?], [:p2, :y?]]
    # tuples = [
      # [:p1, 3, 4], [:p1, 4, 5], [:p1, 5, 6],
      # [:p2, 4], [:p2, 6]
    # ]
    # store = create_store()
    # store.registerPredicate(:p1, 3)
    # store.registerPredicate(:p2, 2)
    # tuples.each {|t| store.addTuple t }
#
    # resT = Set.new
    # result = store.subscribe(:test, plan) do |t|
      # resT << t.to_a
    # end
#
    # assert_equal Set.new([[3,4], [5,6]]), resT
  # end

end



