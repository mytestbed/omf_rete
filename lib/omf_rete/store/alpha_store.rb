require 'set'
require 'omf_rete/store/alpha/alpha_inner_element'
require 'omf_rete/store/alpha/alpha_leaf_element'

module OMF::Rete::Store

  #
  # Class to store tuples for use in MoanaFilter
  #
  class AlphaStore #< MObject
    include OMF::Rete::Store

    attr_reader :length

    # Initialize a tuple store for tuples of
    # fixed length +length+.
    #
    def initialize(length, opts = {})
      @length = length
      @root = Alpha::AlphaInnerElement.new(0, length)
      @index = []
      length.times do @index << {} end
    end


    # Register a +TSet+ and add all tuples currently
    # and in the future matching +pattern+
    #
    def registerTSet(tset, pattern)
      #puts "registerTSet: #{pattern}"
      pat = pattern.collect do |el|
        (el.is_a?(Symbol) && el.to_s.end_with?('?')) ? nil : el
      end
      @root.registerTSet(tset, pat)
      # seed tset which already stored data
      find(pat).each do |t|
        tset.addTuple(t)
      end
      tset
    end

    def createTSet(description, indexPattern)
      tset = Moana::Filter::IndexedTupleSet.new(description, indexPattern)
      registerTSet(tset, description)
      tset
    end

    def addTuple(tarray)
      @length.times do |i|
        item = tarray[i]
        ia = @index[i][item] ||= Set.new
        unless ia.add?(tarray)
          return  # this is a duplicate
        end
      end
      @root.addTuple(tarray)
    end

    # Remove a tuple from the store
    #
    def removeTuple(tarray)
      @length.times do |i|
        item = tarray[i]
        if ia = @index[i][item]
          ia.delete(tarray)
        end
      end
      @root.removeTuple(tarray)
    end

    # Return a set of tuples which match +pattern+. Pattern is
    # a tuples of the same length this store is configured for
    # where any non-nil element is matched directly and any
    # nil element is considered a wildcard.
    #
    def find(pattern)
      #puts "patern: #{pattern.inspect}"
      seta = []
      allWildcards = true
      @length.times do |i|
        if (item = pattern[i])
          if (item != :_)
            allWildcards = false
            res = @index[i][item] || Set.new
            #puts "res: index #{i}, res: #{res.inspect}"
            seta << res
          end
        end
      end

      if (allWildcards)
        res = Set.new
        @index[0].each_value do |s|
          res.merge(s)
        end
        return res
      end
      # get intersection of all returned sets
      if (seta.empty?)
        return Set.new
      end
      res = nil
      seta.each do |s|
        if res
          res = res.intersection(s)
        else
          res = s
        end
        #puts "merge: in: #{s.inspect}, res: #{res.inspect}"
      end
      return res
    end

    def to_s()
      "Store"
    end
  end # Store
end # Moana