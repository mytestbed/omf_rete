
module OMF::Rete
  #
  # This class maintains a set of tuples and
  # supports a block being attached which is
  # being called whenever a tuple is added or
  # removed.
  #
  # The TupleSet is defined by a +description+.
  #
  # The +description+ is an array of the
  # same length as the tuples maintained. Each element,
  # if not nil, names the binding variable associated with it.
  # The position of a binding can be retrieved with
  # +index_for_binding+.
  #
  class AbstractTupleSet

    attr_reader :description
    attr_accessor :source

    def initialize(description, source = nil)
      @description = description
      @source = source
    end

    def register_with_store(store, description)
      @store = store
      raise "BUG ALERT" unless description == @description
      store.registerTSet(self, description)
    end

    # Detach all streams from each other as they are no longer in use
    #
    def detach()
      @source.detach if @source
      puts ">>> UNREGISTER"
      @store.unregisterTSet(self) if @store
    end

    def addTuple(tuple)
      raise 'Abstract class'
    end

    def removeTuple(tuple)
      raise 'Abstract class'
    end

    # Call block for every tuple stored in this set currently and
    # in the future. In other words, the block may be called even after this
    # method returns.
    #
    # The block will be called with one parameters, the
    # tuple added.
    #
    def on_add(&block)
      raise 'Abstract class'
    end

    # Return all stored tuples in an array.
    def to_a
      raise 'Abstract class'
    end

    # Retunr the index into the tuple for the binding variable +bname+.
    #
    # Note: This index is different to the set index used in +IndexedTupleSet+
    #
    def index_for_binding(bname)
      @description.find_index do |el|
        el == bname
      end
    end

    def binding_at(index)
      @description[index]
    end

    def describe(out = STDOUT, offset = 0, incr = 2, sep = "\n")
      raise 'Abstract class'
    end


  end # class
end # module

