
module OMF::Rete
  #
  # This class represents a tuple and includes various ways to access
  # the contained elements..
  #
  class Tuple
    attr_reader :description

    # Return content of tuple as array of elements. The order and names are
    # contained in 'description'. Use the #[] method to more robustly access
    # individual elements.
    #
    def to_a
      @tarray
    end

    # Return content of tuple as a hash. The key is taken from the 'description'.
    #
    def to_hash
      h = {}
      @description.each_with_index do |n, i|
        name = n.to_s.chomp('?').to_sym
        h[name] = @tarray[i]
      end
      h
    end

    # Return a specific element either indicated by index (number) or name
    # as listed in 'description'.
    #
    def [](index_or_name)
      if index_or_name.is_a? Integer
        return @tarray[index_or_number]
      elsif index_or_name.is_a? Symbol
        @description.each_with_index do |n, i|
          return @tarray[i] if n == index_or_name
        end
      end
      raise "Unknown element name: '#{index_or_name}'"
    end

    def initialize(tarray, description)
      @tarray = tarray
      @description = description
    end

    def method_missing(name, *args, &block)
      self[name]
    end

  end
end
