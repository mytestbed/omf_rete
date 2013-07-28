require 'omf_rete/store/alpha_store'

module OMF::Rete::Store

  class WrongNameException < StoreException
    def initialize(name, tuple)
      super "Expected first element in '#{tuple}' to be '#{name}'"
    end
  end

  #
  # This is a store where the first element in each
  # tuple is supposed to have the same name.
  #
  class NamedAlphaStore < AlphaStore
    include OMF::Rete::Store

    # Initialize a tuple store for tuples of
    # fixed length +length+ where the first element
    # is always 'name' (included in length)
    #
    def initialize(name, length, opts = {})
      @name = name
      super length, opts
      #@store = AlphaStore.new(length - 1)
    end

    def addTuple(tarray)
      unless tarray[0] == @name
        raise WrongNameException.new(@name, tarray)
      end
      super
      #@store.addTuple(tarray[1 .. -1])
    end


  end
end
