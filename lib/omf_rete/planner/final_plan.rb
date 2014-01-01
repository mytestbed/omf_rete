
module OMF::Rete::Planner

  # This plan holds the final result stream from which all other streams can be
  # discovered and if necessary, freed.
  #
  #
  class FinalPlan

    def initialize(result_stream)
      @result_stream = result_stream
    end

    def materialize(indexPattern, resultSet, opts, &block)
      raise "Shouldn't be called - THis is just a place holder"
    end

    def describe(out = STDOUT, offset = 0, incr = 2, sep = "\n")
      @result_stream.describe(out, offset, incr, sep)
    end

    def detach()
      @result_stream.detach()
    end
  end

end # module