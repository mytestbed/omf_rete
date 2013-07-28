require 'omf_rete/store/alpha/alpha_element'

module OMF::Rete::Store::Alpha

    class AlphaInnerElement < AlphaElement

      def initialize(level, length)
        super(level)
        @length = length
        @children = {}
        if (level < length)
          @wildChild = AlphaElement.create(level + 1, length)
        end
      end

      # see Store
      #
      def registerTSet(tset, pattern)
        pitem = pattern[@level]
        if (pitem)  # not nil
          child = (@children[pitem] ||= AlphaElement.create(@level + 1, @length))
          child.registerTSet(tset, pattern)
        else # wildcard
          @wildChild.registerTSet(tset, pattern)
        end
      end

      def addTuple(tarray)
        el = tarray[@level]
        if (child = @children[el])
          child.addTuple(tarray)
        end
        @wildChild.addTuple(tarray) if (@wildChild)
      end

      def removeTuple(tarray)
        el = tarray[@level]
        if (child = @children[el])
          child.removeTuple(tarray)
        end
        @wildChild.removeTuple(tarray) if (@wildChild)
      end

    end # AlphaInnerElement

end # Moana::Filter::Store::Alpha