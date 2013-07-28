


# Monkey patch symbol to allow consistent ordering of set keys
unless (:test).respond_to? '<=>'
  class Symbol
    def <=>(o)
      self.to_s <=> o.to_s
    end
  end
end


module OMF::Rete
  module Planner

    # The base exception for all errors related
    class PlannerException < Exception; end

    require 'omf_rete/planner/source_plan'
    require 'omf_rete/planner/plan_level_builder'
    require 'omf_rete/planner/plan_set'
    require 'omf_rete/planner/filter_plan'

    # This class builds all the possible plans for a given
    # query
    #
    class PlanBuilder

      attr_reader :plan, :store
      #
      # query -- query consists of an array of tuple paterns with binding declarations
      # store -- store to attach source sets to
      #
      def initialize(query, store, opts = {})
        @store = store
        @opts = opts

        _parse_query(query)

        @complete_plans = []
        if (@source_cnt == 1)
          # only one source means a trivial plan, the source itself
          @complete_plans = @sources.to_a
        end

      end

      def build()
        level = 0
        maxLevels = @source_cnt + 10 # pull the emergency breaks sometimes
        while (@complete_plans.empty? && level < maxLevels) do
          _iterate()
          level += 1
        end
        if (@complete_plans.empty?)
          raise PlannerException.new("Can't create plan")
        end
        @complete_plans
      end

      def each_plan()
        @complete_plans.each do |p| yield(p) end
      end

      # Return plan with lowest cost
      #
      def best_plan()
        # best_plan = nil
        # lowest_cost = 9999999999
#
        # each_plan do |plan|
          # cost = plan.cost
          # if (cost < lowest_cost)
            # lowest_cost = cost
            # best_plan = plan
          # end
        # end
        best_plan = @complete_plans.min do |p1, p2|
          p1.cost <=> p2.cost
        end
        best_plan
      end


      # Materialize the plan. Create all the relevant operations and tuple sets
      # to realize a configuration for the respective query. Returns the result
      # set.
      #
      def materialize(projectPattern = nil, plan = nil, opts = nil, &block)
        unless plan
          plan = best_plan()
        end
        unless plan
          raise PlannerException.new("No plan to materialize");
        end
        if (plan.is_a?(SourcePlan))
          # This is really just a simple pattern on the store
          _materialize_simple_plan(projectPattern, plan, opts, &block)
        else
          # this is the root of the plan
          if projectPattern
            description = projectPattern
          else
            description = plan.result_set.to_a.sort
          end
          frontS, endS = _materialize_result_stream(plan, projectPattern, opts, &block)
          plan.materialize(nil, frontS, opts, &block)
          endS
        end
      end


      def describe(out = STDOUT, offset = 0, incr = 2, sep = "\n")
        out << "\n=========\n"
        @complete_plans.each do |p|
          out << "------\n"
          p.describe(out, offset, incr, sep)
        end
      end

      private

      # Parse +query+ which is an array of query tuples or filters.
      #
      # This method create a new +SourcePlan+ (to be attached to a store)
      # for every query tuple in the +query+ array.
      #
      def _parse_query(query)
        @query = query
        @sources = Set.new
        @filters = []
        @plans = PlanSet.new
        query.each do |sp|

          if sp.is_a? FilterPlan
            @filters << sp
          elsif sp.is_a? SourcePlan
            @sources << sp
            @plans << sp
          elsif sp.is_a? Array
            unless @store.confirmLength(sp)
              raise PlannerException.new("SubPlan: Expected array of store size, but got '#{sp}'")
            end
            begin
              p = SourcePlan.new(sp, @store)
              @sources << p
              @plans << p
            rescue NoBindingException
              # ignore sources with no bindings in them
            end
          else
            raise PlannerException.new("SubPlan: Unknown sub goal definition '#{sp}'")
          end
        end
        @source_cnt = @sources.size
        if @sources.empty?
          raise PlannerException.new("Query '#{query}' seems to be empty")
        end
      end

      #
      # Array of sources from lower levels to build new plans from
      #
      #  plans -- array of plans to combine
      #  fullCoverSet -- set containing all initial sources
      #
      def _iterate()
#          puts ">>>>>>>> LEVEL >>>>>"
        plans = @plans.to_a.dup
        plans.each_with_index do |plan, i|
          unless (plan.complete?) # don't combine complete plans anymore
            unless (rem = plans[i + 1 .. -1]).empty?
              _build_for_plan(plan, rem)
            end
            unless plan.used?
              _add_plan(plan)
            end
          end
        end
        @plans
      end

      # Compare +plan+ with all remaining plans and create
      # a new plan if it can be combined. If no new plan
      # is created for +plan+ elevated it to this level.
      #
      def _build_for_plan(plan, otherPlans)
        otherPlans.each do |other|
          unless (other.complete?) # don't combine complete plans anymore
            _build_for(plan, other)
          end
        end
      end


      def _build_for(left, right)
#          STDOUT.puts "CHECKING"
#          STDOUT.puts "  LEFT"
#          left.describe
#          STDOUT.puts "  RIGHT"
#          right.describe

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
        jp = JoinPlan.new(left, right, joinSet, resultSet, combinedCover, self)
        _add_plan(jp)
      end

      def _add_plan(plan)
        action = 'DUPLICATE: '
        if (@plans << plan)
          action = 'ADDED: '
          if (plan.cover_set.size == @source_cnt)
            action = 'COMPLETE: '
            @complete_plans << plan
            plan.complete()
          end
        end
#          STDOUT << action
#          plan.describe
      end

      # The +plan+ consists only of a source plan. Create
      # a processing stream and attach a block which extracts
      # the 'bound' elements from the incoming tuple.
      #
      def _materialize_simple_plan(projectPattern, plan, opts, &block)

        unless projectPattern
          # create one from the binding varibales in plan.description
          projectPattern = []
          plan.description.each do |name|
            if name.to_s.end_with?('?')
              projectPattern << name.to_sym
            end
          end
          if (projectPattern.empty?)
            raise NoBindingException.new("No binding declaration in source plan '#{plan.description.join(', ')}'")
          end
        end
        description = projectPattern

        #src = plan.materialize(nil, projectPattern, opts)
        src = ProcessingTupleStream.new(projectPattern, projectPattern, plan.description)
        frontS, endS = _materialize_result_stream(plan, projectPattern, opts, &block)

        src.receiver = frontS
        frontS.source = src

        @store.registerTSet(src, plan.description) if @store

        endS
      end

      # This creates the result stream and stacks all filters on top (if any)
      # It returns the first and last element as an array.
      #
      def _materialize_result_stream(plan, projectPattern, opts, &block)
        plan_description = plan.result_description
        description = projectPattern || plan.result_description
        rs = ResultTupleStream.new(description, &block)

        # This is a very naive plan to add filters. It simple stacks them all at the end.
        # It would be much better to put them right after each source or join which produces
        # the matching binding stream.
        #
        first_filter = nil
        last_filter = nil
        @filters.each do |f|
          fs = f.materialize(plan_description, last_filter, opts)
          if (last_filter)
            last_filter.receiver = fs
          end
          first_filter ||= fs
          last_filter = fs
        end
        if (last_filter)
          last_filter.receiver = rs
          rs.source = last_filter
        end
        [first_filter || rs, rs]
      end


    end # PlanBuilder
  end # Planner
end # module
