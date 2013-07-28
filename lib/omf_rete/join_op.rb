require 'omf_rete/indexed_tuple_set'

module OMF::Rete

  # This class implements the join operation between two
  # +IndexedTupleSets+ feeding into a third, result tuple set.
  # The size of both incoming tuple sets needs to be identical and they
  # are supposed to be indexed on the same list of variables as this is
  # what they wil be joined at.
  #
  # Implementation Note: We first calculate a +combinePattern+
  # from the +description+ of the result set.
  # The +combinePattern+ describes how to create a joined tuple to insert
  # into the result tuple set. The +combinePattern+ is an array of
  # the same size as the result tuple. Each element is a 2-array
  # with the first element describing the input set (0 .. left, 1 .. right)
  # and the second one the index from which to take the value.
  #
  #
  class JoinOP
    def initialize(leftSet, rightSet, resultSet)
      @resultSet = resultSet
      @left = leftSet
      @right = rightSet

      @combinePattern = resultSet.description.collect do |bname|
        side = 0
        unless (i = leftSet.index_for_binding(bname))
          side = 1
          unless (i = rightSet.index_for_binding(bname))
            raise "Can't find binding '#{bname}' in either streams. Should never happen"
          end
        end
        #description << bname
        [side, i]
      end
      @resultLength = @combinePattern.length
      @results = {} # Keep track of how may input tuples create the same result - necessary for 'removeTuple'

      leftSet.on_add_with_index do |index, ltuple|
        if (rs = rightSet[index])
          rs.each do |rtuple|
            add_result(ltuple, rtuple)
          end
        end
      end
      rightSet.on_add_with_index do |index, rtuple|
        if (ls = leftSet[index])
          ls.each do |ltuple|
            add_result(ltuple, rtuple)
          end
        end
      end

      leftSet.on_remove_with_index do |index, ltuple|
        if (index.nil?)
          clear_result()
        else
          if (rs = rightSet[index])
            rs.each do |rtuple|
              remove_result(ltuple, rtuple)
            end
          end
        end
      end
      rightSet.on_remove_with_index do |index, rtuple|
        if (index.nil?)
          clear_result()
        else
          if (ls = leftSet[index])
            ls.each do |ltuple|
              remove_result(ltuple, rtuple)
            end
          end
        end
      end

      # Supporting 'check_for_tuple'
      @left_pattern = @left.description.map do |bname|
        @resultSet.index_for_binding(bname)
      end
      @right_pattern = @right.description.map do |bname|
        @resultSet.index_for_binding(bname)
      end

    end

    # Check if +tuple+ can be produced by this join op. We first
    # check if we can find a match on one side and then request
    # from the other side all the tuples which would lead to full
    # join.
    #
    def check_for_tuple(tuple)
      ltuple = @left_pattern.map {|i| tuple[i]}
      if @left.check_for_tuple(ltuple)
        rtuple = @right_pattern.map {|i| tuple[i]}
        if @right.check_for_tuple(rtuple)
          return true
        end
      end
      return false
    end

    def description()
      @resultSet.description
    end

    def describe(out = STDOUT, offset = 0, incr = 2, sep = "\n")
      out.write(" " * offset)
      result = @combinePattern.collect do |side, index|
        (side == 0) ? @left.binding_at(index) : @right.binding_at(index)
      end
      out.write("join: [#{@left.indexPattern.sort.join(', ')}] => [#{result.sort.join(', ')}]#{sep}")
      @left.describe(out, offset + incr, incr, sep)
      @right.describe(out, offset + incr, incr, sep)
    end

    private

    def add_result(ltuple, rtuple)
      unless @resultLength
        i = 2
      end
      result = Array.new(@resultLength)
      i = 0
      @combinePattern.each do |setId, index|
        t = setId == 0 ? ltuple : rtuple
        result[i] = t[index]
        i += 1
      end

      if @results.key? result
        @results[result] = @results[result] + 1
      else
        @results[result] = 1
        @resultSet.addTuple(result)
      end
      #puts "add: #{result.inspect} (#{@results.inspect})"
    end

    def remove_result(ltuple, rtuple)
      unless @resultLength
        i = 2
      end
      result = Array.new(@resultLength)
      i = 0
      @combinePattern.each do |setId, index|
        t = setId == 0 ? ltuple : rtuple
        result[i] = t[index]
        i += 1
      end
      # Remove it from result set if it has only been added once
      #puts "remove: #{result.inspect} (#{@results.inspect})"
      if count = @results[result]
        if count == 1
          @results.delete(result)
          @resultSet.removeTuple(result)
        else
          @results[result] = count - 1
        end
      else
        raise "Should never happen"
      end
    end

    def clear_result()
      @results = {}
      @resultSet.clear
    end


  end # class
end # module
