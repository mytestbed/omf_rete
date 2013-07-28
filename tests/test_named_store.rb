require 'omf_rete/store'

include OMF::Rete

class TestNamedStore < Test::Unit::TestCase

  def create_store()
    Store.create(3, type: :named_alpha, name: :foo)
  end

  def test_create_store
    store = create_store()
  end

  def test_add_tuple
    store = create_store()
    store.addTuple [:foo, :b, :c]
  end

  def test_add_tuple2
    store = create_store()
    store.add :foo, :b, :c
  end

  def test_add_wrong_named_tuple
    store = create_store()
    assert_raise OMF::Rete::Store::WrongNameException do
      store.add :a, :b, :c
    end
  end


end



