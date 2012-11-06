module OMF::Rete
  module Planner
    
    
    # This class is the super class for all plans
    # 
    #
    class AbstractPlan

      attr_reader :cover_set, :result_set
      
      #
      # coverSet -- set of source plans covered by this plan
      # resultSet -- set of bindings provided by this source
      #
      def initialize(coverSet, resultSet)
        @cover_set = coverSet
        @result_set = resultSet
        @is_used = false
        @is_complete = false
      end
      
      def result_description
        @result_set.to_a.sort
      end
      

      
      # Return true if this plan is a complete one.
      #
      # A complete plan covers (@coverSet) all leaf plans.
      #
      def complete?()
        @is_complete
      end
      
      # Set this plan to be complete
      #
      def complete()
        @is_complete = true
      end
      
      # Return true if used by some higher plan
      #
      def used?()
        @is_used
      end
      
      # Informs the plan that it is used by some higher plan
      #
      def used()
        @is_used = true
      end
    end # PlanBuilder

  end # Planner
end # module