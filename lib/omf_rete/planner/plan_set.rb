#
#

require 'set'

module OMF::Rete
  module Planner
      
      # This is a specialisation of the Set class which uses the
    # hash of an object to determine identity. 
    #
    class PlanSet
      
      def initialize()
        @hash = {}
        @plans = []
      end
      
      # Converts the set to an array.  The order of elements is uncertain.
      def to_a
        @plans
      end
      
      def empty?
        @plans.empty?
      end

      def length
        @plans.length
      end
      
      
      # Returns true if two sets are equal.  The equality of each couple
      # of elements is defined according to Object#eql?.
      def ==(set)
        equal?(set) and return true
    
        set.is_a?(PlanSet) && size == set.size or return false
    
        hash = @hash.dup
        set.all? { |o| hash.include?(o) }
      end
      
      def eql?(o) # :nodoc:
        return false unless o.is_a?(PlanSet)
        @plans.eql?(o.instance_eval{@plans})
      end

      # Returns true if the set contains the given object.
      def include?(o)
        @hash.has_value?(o)
      end
    
      # Calls the given block once for each element in the set, passing
      # the element as parameter.  Returns an enumerator if no block is
      # given.
      def each
        block_given? or return enum_for(__method__)
        @plans.each do |o| yield(o) end
        self
      end
    
      # Adds the given object to the set and returns false if object is already
      # in the set, true otherwise.
      #
      def add(o)
        really_added = false
        oh = o.hash
        unless @hash.key?(oh)
          really_added = true
          @hash[oh] = o
          @plans << o
        end
        really_added 
      end
      alias << add

    end # class
  end # module
end # module

      