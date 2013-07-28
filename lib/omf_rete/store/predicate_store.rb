require 'omf_rete/store/named_alpha_store'

module OMF::Rete::Store

  class UnknownPredicateException < StoreException
    def initialize(pred, tuple, stores = {})
      if pred
        super "Unknown predicate '#{pred}' in '#{tuple}' - (#{stores.keys})"
      else
        super "Missing predicate in '#{tuple}'"
      end
    end
  end

  class AlreadyRegisteredPredicateException < StoreException
    def initialize(pred)
      super "Predicate '#{pred}' is already registered"
    end
  end

  #
  # This store supports  'predicate' tuples. The predicate of a tuple is identified
  # by it's first element and each predicate can have a different scheme (tuple length).
  # Each predicate needs to be registered through 'registerPredicate'.
  #
  # Subscriptions and 'find' queries need to name the predicate. In other words, they CANNOT
  # span multiple predicates.
  #
  class PredicateStore
    include OMF::Rete::Store

    def initialize(opts = {})
      @stores = {}
    end

    # Register a new predicate 'pred_name' whose tuples are of 'length'.
    #
    def registerPredicate(pred_name, length, opts = {})
      pred_name = pred_name.to_sym
      if @stores.key? pred_name
        raise AlreadyRegisteredPredicateException.new(pred_name)
      end
      @stores[pred_name] = NamedAlphaStore.new(pred_name, length, opts)
    end

    # Register a 'store' for predicate 'pred_name'.
    #
    def registerPredicateStore(pred_name, store)
      pred_name = pred_name.to_sym
      if @stores.key? pred_name
        raise AlreadyRegisteredPredicateException.new(pred_name)
      end
      @stores[pred_name] = store
    end

    ## Store API ###

    def registerTSet(tset, pattern)
      tset = get_store(pattern).registerTSet(tset, pattern)
      #puts ">>> Register tset - #{pattern} - #{tset}"
      tset
    end

    def addTuple(tarray)
      get_store(tarray).addTuple(tarray)
    end

    def removeTuple(tarray)
      get_store(tarray).removeTuple(tarray)
    end

    def find(pattern)
      get_store(pattern).find(pattern)
    end

    def to_s()
      "Predicate Store"
    end

    def confirmLength(tuple)
      tuple.is_a?(Array) && get_store(tuple).confirmLength(tuple)
    end


    protected

    def get_store(tuple)
      pred = tuple[0]
      unless !pred.nil? && store = @stores[pred.to_sym]
        raise UnknownPredicateException.new(pred, tuple, @stores)
      end
      store
    end

  end # class
end # module