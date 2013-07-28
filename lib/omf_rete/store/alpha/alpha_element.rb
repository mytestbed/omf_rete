
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


end # Moana::Filter::Store::Alpha