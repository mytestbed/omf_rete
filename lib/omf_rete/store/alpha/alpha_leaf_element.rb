
require 'omf_rete/store/alpha/alpha_element'

module OMF::Rete::Store::Alpha

  # Module internal class, will only be instantiated by +Store+
  #
  class AlphaLeafElement < AlphaElement

    def initialize(level, store)
      super
      @tsetIndex = {}
      @tsetWildcards = []
    end

    # see Store
    #
    def registerTSet(tset, pattern)
      pitem = pattern[@level]
      leaf = (@level == @length)
      a = pitem ? (@tsetIndex[pitem] ||= []) : @tsetWildcards
      a << tset
      @store.onUnregisterTSet(tset) do
        a.delete(tset)
      end
      # if (pitem)  # not nil
        # (@tsetIndex[pitem] ||= []) << tset
      # else # wildcard
        # @tsetWildcards << tset
      # end
    end

    def addTuple(tarray)
      # check if we have any matching tsets
      item = tarray[@level]
      if (arr = @tsetIndex[item])
        arr.each do |s|
          s.addTuple(tarray)
        end
      end
      @tsetWildcards.each do |s|
        s.addTuple(tarray)
      end
    end

    def removeTuple(tarray)
      # check if we have any matching tsets
      item = tarray[@level]
      if (arr = @tsetIndex[item])
        arr.each do |s|
          s.removeTuple(tarray)
        end
      end
      @tsetWildcards.each do |s|
        s.removeTuple(tarray)
      end
    end

  end # class

end # Moana::Filter::Store::Alpha