
module OMF::Rete::Store::Alpha

    # Module internal class, will only be instantiated by +Store+
    #
    class AlphaElement

      def self.create(level, length, store)
        rem = length - level
        if (rem > 1)
          AlphaInnerElement.new(level, length, store)
        else
          AlphaLeafElement.new(level, store)
        end
      end

      def initialize(level, store)
        @level = level
        @store = store
      end

    end


end # Moana::Filter::Store::Alpha