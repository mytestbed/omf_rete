require 'set'
require 'omf_rete/store/predicate_store'

module OMF::Rete::Store

  class WrongPatternLengthException < StoreException
    def initialize(exp_length, tuple)
      super "Expected tuple '#{tuple}' to be of length '#{exp_length}'"
    end
  end

  #
  # Turns a standard object into a store.
  #
  # NOTE: This store is NOT tracking changes to the
  # state of the object. It is assumed to stay constant
  # while it is in this store.
  #
  class ObjectStore
    include OMF::Rete::Store



    # @param opts :include_object Make the fist element the object
    def initialize(opts = {})
      @include_object = opts[:name] || (opts[:include_object] == true ? self : nil)
      @object = nil
      @tsets = {}
    end

    # Make this store represent 'obj'. this will
    # 'eject' the currently represented object (if exist)
    #
    def representObject(obj)
      @object = obj
      # First clear registered tsets and then seed with state from 'obj'
      @tsets.each do |tset, pat|
        tset.clear()
      end
      @tsets.each do |tset, pat|
        find(pat).each do |t|
          tset.addTuple(t)
        end
      end
      obj
    end

    # Register a +TSet+ and add all the
    # object's state matching the pattern
    #
    def registerTSet(tset, pattern)
      pat = pattern.collect do |el|
        (el.is_a?(Symbol) && el.to_s.end_with?('?')) ? nil : el
      end
      @tsets[tset] = pat

      # seed tset which already stored data
      find(pat).each do |t|
        tset.addTuple(t)
      end
      tset
    end

    # Return a set of tuples which match +pattern+. Pattern is
    # a tuples where the first element (include_object == false)
    # or the second element (include_object == true) is a property
    # of this object. If the next element is nil, return the value.
    # if the next one is not nil, only return a tuple if it is set
    # to the same value.
    #
    # If the property value is an Enumerable, return a separate tuple
    # for every value returned by the enumerable.
    #
    def find(pattern)
      res = Set.new
      if @include_object
        raise WrongPatternLengthException.new(3, pattern) unless pattern.length == 3
        obj = pattern[0]
        return res if obj && obj != @include_object # not for us
      else
        raise WrongPatternLengthException.new(2, pattern) unless pattern.length == 2
      end
      unless pred = @include_object ? pattern[1] : pattern[0]
        raise OMF::Rete::Store::UnknownPredicateException.new(pred, pattern)
      end
      pred = pred.to_sym
      return res unless @object.respond_to? pred

      val = @object.send(pred)
      if exp_value = @include_object ? pattern[2] : pattern[1]
        # Only return tuple if identical
        a = [pred, exp_value]
        a.insert(0, @include_object) if @include_object
        # need to check if same
        if (val.is_a?(Enumerable) ? val.include?(exp_value) : val == exp_value)
          res << a
        end
        return res
      end

      a = [pred]
      a.insert(0, @include_object) if @include_object
      if val.is_a?(Enumerable)
        res = Set.new(val.map {|v| a.dup << v})
      else
        res << (a << val)
      end
      return res
    end

    def to_s()
      "ObjectStore"
    end

    def confirmLength(tuple)
      tuple.is_a?(Array) && tuple.length == (@include_object ? 3 : 2)
    end
  end # class
end # module