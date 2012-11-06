
require 'omf_rete/tuple_stream'

module OMF::Rete
  module Planner
    
    
    # This class represents a planned join op.
    # 
    #
    class JoinPlan < AbstractPlan
      
      # stream1 - first stream to join
      # stream2 - second stream to join
      # joinSet - set of bindings to join on
      # resultSet - set of bindings in result
      # coverSet - set of leaf nodes contributing to this result
      #
      def initialize(stream1, stream2, joinSet, resultSet, coverSet, planBuilder)
        super coverSet, resultSet 
        
        @planBuilder = planBuilder
        @left = stream1
        @right = stream2
        @join_set = joinSet
      end

      # Materialize the plan. Create all the relevant operations and tuple sets
      # to realize a configuration for the respective query. Returns the result
      # set.
      #
      def materialize(indexPattern, resultSet, opts, &block)
        unless resultSet
          description = @result_set.to_a.sort
          resultSet = IndexedTupleSet.new(description, indexPattern, nil, opts)
        end
          
        indexPattern = @join_set.to_a
        leftSet = @left.materialize(indexPattern, nil, opts)
        rightSet = @right.materialize(indexPattern, nil, opts)
        op = JoinOP.new(leftSet, rightSet, resultSet)
        resultSet.source = op
        resultSet
      end

      # Create a hash for this plan which allows us to
      # to identify identical plans.
      #
      # Please note, that there is most likely a mroe efficient way to 
      # calculate a hash with the above properties
      #
      def hash()
        unless @hash
          s = StringIO.new
          describe(s, 0, 0, '|')
          str = s.string
          @hash = str.hash
        end
        @hash
      end
      
      # Return the cost of this plan.
      #
      # TODO: Some more meaningful heuristic will be nice
      #
      def cost()
        unless @cost
          lcost = @left.cost()
          rcost = @right.cost()
          #@cost = 1 + 1.2 * (lcost > rcost ? lcost : rcost)
          @cost = 1 + 1.2 * (lcost + rcost)
          
        end
        @cost
      end
      
      def describe(out = STDOUT, offset = 0, incr = 2, sep = "\n")
        out.write(" " * offset)
        result = @result_set.to_a.sort
        join = @join_set.to_a.sort
        out.write("join: [#{join.join(', ')}] => [#{result.join(', ')}] cost: #{cost}#{sep}")
        @left.describe(out, offset + incr, incr, sep) 
        @right.describe(out, offset + incr, incr, sep) 
      end
      
      def to_s
        result = @result_set.to_a.sort
        join = @join_set.to_a.sort
        "JoinPlan [#{join.join(', ')}] out: [#{result.join(', ')}]"
      end        
    end # PlanBuilder

  end # Planner
end # module
