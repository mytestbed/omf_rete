
require 'omf_rete'

  
module OMF::Rete::Store
  DEF_TYPE = :alpha
  
  def self.create(length, opts = {})
    case (type = opts[:type] || DEF_TYPE)
    when :alpha
      require 'omf_rete/store/alpha/alpha_store'
      return OMF::Rete::Store::Alpha::Store.new(length, opts)
    else
      raise "Unknown store type '#{type}'"
    end
  end
  
  #--- INTERFACE ---
  
  # def query(queryPattern, projectPattern = nil, &block)
    # raise "'query' - Not implemented."
  # end
  
  def subscribe(name, query, out_pattern = nil, &block)
    require 'omf_rete/planner/plan_builder'

    pb = OMF::Rete::Planner::PlanBuilder.new(query, self)
    pb.build
    pb.materialize(out_pattern, &block)
  end
  
  def addTuple(tarray)
  end
  
  # alias
  def add(*els)
    addTuple(els)
  end

  # Return a set of tuples which match +pattern+. Pattern is
  # a tuples of the same length this store is configured for
  # where any non-nil element is matched directly and any
  # nil element is considered a wildcard.
  #
  def find(pattern)
  end

  # Register a function to be called whenever a query is performed
  # on the store. The arguments to the proc are identical to that
  # of +query+. The returned tuple set is added to the store and
  # returned with any other tuples stored which match the query
  # pattern.
  #
  def on_query(&requestProc)
  end

end