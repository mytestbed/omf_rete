
require 'omf_rete/planner/plan_builder'
require 'omf_rete/planner/abstract_plan'
require 'omf_rete/indexed_tuple_set'
require 'set'

module OMF::Rete
  module Planner

    # Thrown if the plan doesn't contain any bindings
    class NoBindingException < PlannerException; end

    # This class represents a planned join op.
    #
    #
    class SourcePlan < AbstractPlan
      attr_reader :description
      attr_reader :source_set  # tuple set created by this plan

      #
      # description - description of tuples contained in set
      # store - store to attach +source_set+ to
      #
      def initialize(description, store = nil, check_for_empty_result_set = true)
        @description = description
        # the result set consists of all the binding declarations
        # which are symbols with trailing '?'
        resultSet = Set.new
        description.each do |name|
          if name.to_s.end_with?('?')
            resultSet << name.to_sym
          end
        end
        if (check_for_empty_result_set && resultSet.empty?)
          raise NoBindingException.new("No binding declaration in sub plan '#{description.join(', ')}'")
        end
        coverSet = Set.new([self])
        super coverSet, resultSet

        #raise Exception unless store.kind_of?(Moana::Filter::Store)
        @store = store
      end

      # Materialize the plan. Returns a tuple set.
      #
      def materialize(indexPattern, projectPattern, opts)
        unless indexPattern
          # this plan only consists of a single source
          projectPattern ||= result_description
          @source_set = ProcessingTupleStream.new(projectPattern, projectPattern, @description)
        else
          @source_set = OMF::Rete::IndexedTupleSet.new(@description, indexPattern)
        end
        #@store.registerTSet(@source_set, @description) if @store
        @source_set.register_with_store(@store, @description)
      end

      # Return the cost of this plan.
      #
      # TODO: Some more meaningful heuristic will be nice
      #
      def cost()
        unless @cost
          @cost = @description.inject(0) do |val, el|
            val + ((el.nil? || el.to_s.end_with?('?')) ? 1 : 0.1)
          end
        end
        @cost
      end


      def describe(out = STDOUT, offset = 0, incr = 2, sep = "\n")
        @source_set.describe(out, offset, incr, sep) if @source_set
      end

    end # SourcePlan

  end # module
end # module