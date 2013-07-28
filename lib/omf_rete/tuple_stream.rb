
require 'omf_rete/tuple'

module OMF::Rete
  #
  # This class provides functionality to process a 
  # stream of tuples. 
  #
  class AbstractTupleStream
    attr_accessor :source
    attr_reader :description
    
    def initialize(description, source = nil)
      @description = description 
      @source = source
    end

    def index_for_binding(bname)
      @description.find_index do |el|
        el == bname
      end
    end
    
    # Return true if +tuple+ can be produced by this stream through the
    # normal (+addTuple+) channels.
    #
    def check_for_tuple(tuple)
      raise "Method 'check_for_tuple' is not implemented"
    end
    
    def describe(out = STDOUT, offset = 0, incr = 2, sep = "\n")
      out.write(" " * offset)
      _describe(out, sep)
      if @source
        @source.describe(out, offset + incr, incr, sep)
      end
    end
  end


  # A processing tuple stream calls the associated processing block
  # for every incoming tuple and forwards what is being returned by
  # this block to the +receiver+. The return value of the block
  # is assumed by a tuple as well. If the return value is nil,
  # nothing is forwarded and the incoming tuple is essentially dropped.
  #
  class ProcessingTupleStream < AbstractTupleStream
    attr_accessor :receiver
    
    def initialize(project_pattern, out_description = project_pattern, in_description = nil, receiver = nil, &block)
      @project_pattern = project_pattern
      super out_description
      @result_size = out_description.size
      if in_description
        self.inDescription = in_description
      end
      @receiver = receiver
      @on_add_block = block
    end
    
    def on_add(&block)
      @on_add_block = block
    end
    
    def on_remove(&block)
      @on_remove_block = block
    end

    def addTuple(tuple)
      if (result = process(tuple, @on_add_block))
        @receiver.addTuple(result)
      end
    end    
    
    def removeTuple(tuple)
      if (result = process(tuple, @on_remove_block))
        @receiver.removeTuple(result)
      end
    end    

    def source=(source)
      super
      if source
        self.inDescription = source.description
      end
    end

    def inDescription=(in_description)
      if in_description
        @result_map = @project_pattern.collect do |name|
          index = in_description.find_index do |n2| name == n2 end
          if index.nil?
            raise "Unknown selector '#{name}'"
          end
          index
        end
      end
    end
    
    private
    
    def process(tuple, block)
      if @result_map
        rtuple = @result_map.collect do |i| tuple[i] end
      else
        rtuple = tuple
      end
      result = block ? block.call(*rtuple) : rtuple
      if (result)
        result = verify_result(result, tuple)
      end
      result
    end

    def verify_result(result, original_tuple)
      unless result.kind_of?(Array) && result.size == @result_size
        raise "Expected block to return an array of size '#{@result_size}', but got '#{result.inspect}' - #{block}"
      end
      result
    end

    
    def _describe(out, sep )
      out.write("processing#{sep}")
    end

  end # ProcessingTupleStream

  # A result tuple stream calls the associated processing block
  # for every incoming tuple.
  #
  # TODO: This should really be a subclass of +ProcessingTupleStream+, but
  # we have supress_duplicates in this class which may be useful for 
  # +ProcessingTupleStream+ as well.
  #
  class ResultTupleStream < AbstractTupleStream

    def initialize(description, supress_duplicates = true, &block)
      super description
      @block = block
      if supress_duplicates
        @results = Set.new
      end
    end
    
    def source=(source)
      @source = source
      if @source.description != @description
        @result_map = @description.collect do |name|
          index = @source.description.find_index do |n2| name == n2 end
          if index.nil?
            raise "Unknown selector '#{name}'"
          end
          index
        end
      end
    end
    
    def addTuple(tuple)
      if @result_map
        ta = @result_map.collect do |i| tuple[i] end
      else
        ta = tuple
      end
      rtuple = Tuple.new(ta, @description)
      if @results
        if @results.add?(ta)
          @block.arity == 1 ? @block.call(rtuple) : @block.call(rtuple, :add)          
        end
      else
        @block.arity == 1 ? @block.call(rtuple) : @block.call(rtuple, :add)
      end
    end
    
    def removeTuple(tuple)
      if @result_map
        ta = @result_map.collect do |i| tuple[i] end
      else
        ta = tuple
      end
      rtuple = Tuple.new(ta, @description)
      if @results
        @results.delete(ta)
      end
      @block.arity == 1 ? @block.call(rtuple) : @block.call(rtuple, :remove)
    end
    
    
    # Return true if +tuple+ can be produced by this stream. A
    # +ResultStream+ only narrows a stream, so we need to
    # potentially expand it (with nil) and pass it up to the
    # +source+ of this stream.
    #
    def check_for_tuple(tuple)
      if @sourcce 
        # should check if +tuple+ has the same size as description
        if @result_map
          # need to expand
          unless @expand_map
            @expand_map = @source.description.collect do |name|
              index = @description.find_index do |n2| name == n2 end
            end              
          end
          up_tuple = @expand_map.collect do |i| i nil? ? nil : tuple[i] end
        else
          up_tuple = tuple
        end
        @source.check_for_tuple(up_tuple)
      end
    end

    private
    
    def _describe(out, sep )
      out.write("out: [#{@description.join(', ')}]#{sep}")
    end
  end # ResultTupleStream

  # A filtering tuple stream calls the associated processing block
  # for every incoming tuple and forwards the incoming tuple if the 
  # the block returns true, otherwise it drops the tuple.
  #
  class FilterTupleStream < ProcessingTupleStream

    def initialize(project_pattern, description = project_pattern, receiver = nil, &block)
      super project_pattern, description, description, receiver, &block
    end
    
    # Return true if +tuple+ can be produced by this stream. For
    # this we need to check first if it would pass this filter
    # before we check if the source for this filter is being
    # able to produce the tuple in question.
    #
    # TODO: This currently doesn't work for tuples with wild cards.
    #
    def check_for_tuple(tuple)
      if @sourcce 
        # should check if +tuple+ has the same size as description
        if @result_map
          rtuple = @result_map.collect do |i| tuple[i] end
        else
          rtuple = tuple
        end
        if @block.call(*rtuple)
          @source.check_for_tuple(tuple)
        end
      end
    end
    
    private
    
    def verify_result(decision, original_tuple)
      decision ? original_tuple : nil
    end    
    
    def _describe(out, sep )
      out.write("filtering#{sep}")
    end

  end # class
end # module

