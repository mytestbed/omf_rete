require 'omf_rete/store/alpha/alpha_element'

module OMF::Rete::Store::Alpha
   
    # Module internal class, will only be instantiated by +Store+
    #
    class AlphaElement
      
      def self.create(level, length)
        rem = length - level
        if (rem > 1)
          AlphaInnerElement.new(level, length)
        else
          AlphaLeafElement.new(level)
        end
      end
      
      def initialize(level)
        @level = level
      end

    end

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
    end # AlphaInnerElement
    
    # Module internal class, will only be instantiated by +Store+
    #
    class AlphaLeafElement < AlphaElement

      def initialize(level)
        super
        @tsetIndex = {}
        @tsetWildcards = []
      end
      
      # see Store
      #
      def registerTSet(tset, pattern)
        pitem = pattern[@level]
        leaf = (@level == @length)
        if (pitem)  # not nil
          (@tsetIndex[pitem] ||= []) << tset
        else # wildcard
          @tsetWildcards << tset
        end
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
      


    end # AlphaLeafElement
    
end # Moana::Filter::Store::Alpha