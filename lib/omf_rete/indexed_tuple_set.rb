require 'omf_rete/abstract_tuple_set'

module OMF::Rete
  #
  # This class maintains a set of tuples and
  # supports a block being attached which is
  # being called whenever a tuple is added or
  # removed.
  #
  # The IndexedTupleSet is defined by a +description+ and an
  # +indexPattern+.
  #
  # The +description+ is an array of the
  # same length as the tuples maintained. Each element,
  # if not nil, names the binding variable associated with it.
  # The position of a binding can be retrieved with
  # +index_for_binding+.
  #
  # The +indexPattern+ describes which elements of the inserted
  # tuple are being combined in an array to form the index
  # key for each internal tuple. The elements in the +indexPattern+
  # are described by the binding name.
  #
  #
  class IndexedTupleSet < AbstractTupleSet

    attr_reader :indexPattern
    attr_writer :transient # if true only process tuple but don't store it

    def initialize(description, indexPattern, source = nil, opts = {})
      super description, source
      if (indexPattern.length == 0)
        raise "Expected index to be non-nil (#{description.join(', ')})"
      end
      @indexPattern = indexPattern
      @indexMap = indexPattern.collect do |bname|
        index_for_binding(bname)
      end

      @index = {}
    end

    def addTuple(tuple)
      key = @indexMap.collect do |ii|
        tuple[ii]
      end

      if @transient
        @onAddBlockWithIndex.call(key, tuple) if @onAddBlockWithIndex
        @onAddBlock.call(tuple) if @onAddBlock
      else
        vset = (@index[key] ||= Set.new)
        if vset.add?(tuple)
          # new value
          @onAddBlockWithIndex.call(key, tuple) if @onAddBlockWithIndex
          @onAddBlock.call(tuple) if @onAddBlock
        end
      end
      tuple # return added tuple
    end

    def removeTuple(tuple)
      key = @indexMap.collect do |ii|
        tuple[ii]
      end

      if @transient
        @onRemoveBlockWithIndex.call(key, tuple) if @onRemoveBlockWithIndex
        @onRemoveBlock.call(tuple) if @onRemoveBlock
      else
        vset = @index[key]
        if vset
          vset.delete(tuple)
          @onRemoveBlockWithIndex.call(key, tuple) if @onRemoveBlockWithIndex
          @onRemoveBlock.call(tuple) if @onRemoveBlock
        end
      end
      tuple # return removed tuple
    end

    # Clear index
    def clear()
      @onRemoveBlockWithIndex.call(nil, nil) if @onRemoveBlockWithIndex
      @onRemoveBlock.call(nil) if @onRemoveBlock
      @index = {}
    end



    # Call block for every tuple stored in this set currently and
    # in the future. In other words, the block may be called even after this
    # method returns.
    #
    # The block will be called with one parameters, the
    # tuple added.
    #
    # Note: Only one +block+ can be registered at a time
    #
    def on_add(&block)
      @index.each do |index, values|
        values.each do |v|
          block.call(v)
        end
      end
      @onAddBlock = block
    end


    # Call block for every tuple stored in this set currently and
    # in the future. In other words, the block may be called even after this
    # method returns.
    #
    # The block will be called with two parameters, the index of the tuple followed by the
    # tuple itself.
    #
    # Note: Only one +block+ can be registered at a time
    #
    def on_add_with_index(&block)
      @index.each do |index, values|
        values.each do |v|
          block.call(index, v)
        end
      end
      @onAddBlockWithIndex = block
    end

    # Call block for every tuple removed from this set in the future.
    # In other words, the block may be called after this
    # method returns.
    #
    # The block will be called with one parameters, the
    # tuple removed. If the parameter is nil, everything has
    # been removed (cleared)
    #
    # Note: Only one +block+ can be registered at a time
    #
    def on_remove(&block)
      @onRemoveBlock = block
    end


    # Call block for every tuple removed from this set
    # in the future. In other words, the block may be called even after this
    # method returns.
    #
    # The block will be called with two parameters, the index of the tuple followed by the
    # tuple itself. If both parameters are nil, everything has
    # been removed (cleared)
    #
    # Note: Only one +block+ can be registered at a time
    #
    def on_remove_with_index(&block)
      @onRemoveBlockWithIndex = block
    end


    # Return the set of tuples index by +key+.
    # Will return nil if nothing is stored for +key+
    #
    def [](key)
      res = @index[key]
      res
    end

    # Return all stored tuples in an array.
    def to_a
      a = []
      @index.each_value do |s|
        s.each do |t|
          a << t
        end
      end
      a
    end

    # Return all stored tuples in a set.
    def to_set
      a = Set.new
      @index.each_value do |s|
        s.each do |t|
          a << t
        end
      end
      a
    end



    def describe(out = STDOUT, offset = 0, incr = 2, sep = "\n")
      out.write(" " * offset)
      desc = @description.collect do |e| e || '*' end
      out.write("ts: [#{desc.join(', ')}]")
      ind = @indexMap.collect do |i| @description[i] end
      out.write("  (index: [#{ind.sort.join(', ')}])#{sep}")
      @source.describe(out, offset + incr, incr, sep) if @source
    end

  end # class IndexedTupleSet
end # module

