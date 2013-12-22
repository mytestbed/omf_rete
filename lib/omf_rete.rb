


module OMF
  module Rete

    # Create a Rete engine to operate on.
    #
    # @param opts :tuple_length Length of tuple if only one type is used
    #
    def self.create_engine(opts = {})
      require 'omf_rete/store'
      Store.create(opts.delete(:tuple_length), opts)

    end

    # Defines a filter on a tuple stream. The argument is either a variable
    # number of binding variables with which the associated block is called.
    # If the argument are two arrays, the first one holds the above described
    # bindings for the block, while the second one describes the tuple returned
    # by the block.
    #
    def self.filter(*projectPattern, &block)
      require 'omf_rete/planner/filter_plan'
      if projectPattern[0].kind_of? Array
        if projectPattern.size != 2
          raise "Wrong arguments for 'filter'. See documentation."
        end
        outDescription = projectPattern[1]
        projectPattern = projectPattern[0]
      else
        outDescription = nil
      end

      FilterPlan.new(projectPattern, outDescription, &block)
    end

    def self.differ(binding1, binding2)
      filter(binding1, binding2) do |b1, b2|
        b1 != b2
      end
    end

  end # Filter
end # Moana
