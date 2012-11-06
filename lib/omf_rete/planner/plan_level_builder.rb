
require 'omf_rete/planner/join_plan'

module OMF::Rete
  module Planner
      
      
    # This class builds all the possible plans for a given 
    # level of the plan forest.
    #
    class PlanLevelBuilder
      
      attr_reader :plans, :complete_plans
      
      # fullCover -- Set of all sources to cover
      # 
      def initialize(sources)
        @fullCover = sources
        @complete_plans = []
        @plans = sources.clone
      end
      
      #
      # Array of sources from lower levels to build new plans from
      #
      #  plans -- array of plans to combine
      #  fullCoverSet -- set containing all initial sources
      #
      def build()
        plans = @plans.to_a
        plans.each_with_index do |plan, i|
          unless (rem = plans[i + 1 .. -1]).nil?
            build_for_plan(plan, rem)
          end
          unless plan.used?
            add_plan(plan)
          end
        end
        @plans
      end
      
      def describe(out = STDOUT, offset = 0, incr = 2, sep = "\n")
        @plans.each do |p|
          p.describe(out, offset, incr, sep)
        end
      end
      

      private

      
      # Compare +plan+ with all remaining plans and create
      # a new plan if it can be combined. If no new plan
      # is created for +plan+ elevated it to this level.
      #
      def build_for_plan(plan, otherPlans)
        otherPlans.each do |other|
          build_for(plan, other)
        end
      end
      
      
      def build_for(left, right)
        lcover = left.cover_set
        rcover = right.cover_set
        combinedCover = lcover + rcover
        combinedSize = combinedCover.size
        if (lcover.size == combinedSize || rcover.size == combinedSize)
          return nil # doesn't get us closer to a solution
        end
        
        joinSet = left.result_set.intersection(right.result_set)
        if (joinSet.empty?)
          return nil # nothing to join            
        end
        
        resultSet = left.result_set + right.result_set
        left.used
        right.used
        jp = JoinPlan.new(left, right, joinSet, resultSet, combinedCover)
        add_plan(jp)
      end
      
      def add_plan(plan)
        if (plan.cover_set == @fullCover)
          @complete_plans << plan
        end
        @plans << plan
      end
    
    end # PlanBuilder

  end # Planner
end # module
