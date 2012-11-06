
require 'omf_rete/planner/plan_builder'
require 'omf_rete/planner/abstract_plan'
require 'set'

module OMF::Rete
  module Planner
    
    # This class represents a filter operation on a binding stream.
    # 
    #
    class FilterPlan
      attr_reader :description
      
      #
      # resultSet - set of bindings provided by this source
      #
      def initialize(projectPattern, outDescription = nil, &block)
        @projectPattern = projectPattern
        @description = outDescription #|| projectPattern.sort
        @block = block
      end
      
      
      def materialize(description, source, opts)
        # A filter has the same in as well as out description as it doesn't change
        # the tuple just potentially drop it.
        #  
        pts = FilterTupleStream.new(@projectPattern, description, &@block)
        pts.source = source
#          if (in_description == @projectPattern)
#            pts.on_add &@block
#          else
#            projectIndex = @projectPattern.collect do |bname|
#              pts.index_for_binding(bname)
#            end
#            pts.on_add do |*t|
#              pt = projectIndex.collect do |index|
#                t[index]
#              end
#              @block.call(*pt)
#            end
#          end
        pts
      end
    end # FilterPlan

  end # Planner
end # module     