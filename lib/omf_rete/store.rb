
require 'omf_rete'


module OMF::Rete::Store

  class StoreException < Exception; end

  class NotImplementedException < StoreException; end
  class UnknownSubscriptionException < StoreException; end

  DEF_TYPE = :alpha

  def self.create(length = -1, opts = {})
    case (type = opts[:type] || DEF_TYPE)
    when :alpha
      require 'omf_rete/store/alpha_store'
      return OMF::Rete::Store::AlphaStore.new(length, opts)
    when :named_alpha
      require 'omf_rete/store/named_alpha_store'
      return OMF::Rete::Store::NamedAlphaStore.new(opts.delete(:name), length, opts)
    when :predicate
      require 'omf_rete/store/predicate_store'
      return PredicateStore.new(opts)
    when :object
      require 'omf_rete/store/object_store'
      return ObjectStore.new(opts)
    else
      raise "Unknown store type '#{type}'"
    end
  end

  #--- INTERFACE ---

  # def query(queryPattern, projectPattern = nil, &block)
    # raise "'query' - Not implemented."
  # end

  def subscribe(name, query, out_pattern = nil, &block)
    if name && @plans[name]
      raise StoreException.new "Already have subscription '#{name}'."
    end

    require 'omf_rete/planner/plan_builder'

    pb = OMF::Rete::Planner::PlanBuilder.new(query, self)
    pb.build
    plan = pb.materialize(out_pattern, &block)
    if name
      @plans[name] = plan
    end
    plan
  end
  alias :add_rule :subscribe

  def unsubscribe(name_or_plan)
    if name_or_plan.is_a? OMF::Rete::Planner::FinalPlan
      plan = name_or_plan
    else
      plan = @plans.delete(name_or_plan)
    end
    unless plan
      raise UnknownSubscriptionException.new("Unknown subscription '#{name_or_plan}'")
    end
    plan.detach
  end

  # Run a query against the store. This is essentially a short lived subscription
  # may not be catch everything if there are inserts at the same time.
  #
  def query(query, out_pattern = nil)
    result = []
    plan = subscribe(null, query, out_pattern) do |t|
      result << t
    end
    unsubscribe(plan)
    result
  end

  def addTuple(tarray)
    raise NotImplementedException.new
  end

  # alias
  def add(*els)
    addTuple(els)
  end
  alias :add_fact :add

  # Remove a tuple from the store
  #
  def removeTuple(*els)
    raise NotImplementedException.new
  end

  # alias
  def remove(*els)
    removeTuple(els)
  end
  alias :remove_fact :remove


  # Return a set of tuples which match +pattern+. Pattern is
  # a tuples of the same length this store is configured for
  # where any non-nil element is matched directly and any
  # nil element is considered a wildcard.
  #
  def find(pattern)
    raise NotImplementedException.new
  end

  # Register a function to be called whenever a query is performed
  # on the store. The arguments to the proc are identical to that
  # of +query+. The returned tuple set is added to the store and
  # returned with any other tuples stored which match the query
  # pattern.
  #
  def on_query(&requestProc)
    raise NotImplementedException.new
  end

  def createTSet(description, indexPattern)
    tset = OMF::Rete::IndexedTupleSet.new(description, indexPattern)
    registerTSet(tset, description)
    tset
  end

  # Return true if tuple (or pattern) is a valid one for this store
  #
  def confirmLength(tuple)
    tuple.is_a?(Array) && tuple.length == @length
  end

  protected
  def store_initialize()
    @plans = {}
  end


end