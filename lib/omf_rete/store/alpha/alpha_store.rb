require 'set'
require 'omf_rete/store/alpha/alpha_inner_element'
require 'omf_rete/store/alpha/alpha_leaf_element'

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
  
  #
  # Class to store tuples for use in MoanaFilter
  #
  class Store #< MObject
    include OMF::Rete::Store
    
    attr_reader :length
    
    # Initialize a tuple store for tuples of
    # fixed length +length+.
    #
    def initialize(length, opts = {})
      @length = length
      @root = AlphaInnerElement.new(0, length)
      @index = []
      length.times do @index << {} end 
    end
    
    def query(queryPattern, projectPattern = nil, &block)
      pb = PlanBuilder.new(queryPattern, self)
      pb.build
      pb.materialize(projectPattern, &block)
    end
    
    # Register a +TSet+ and add all tuples currently
    # and in the future matching +pattern+
    #
    def registerTSet(tset, pattern)
      pat = pattern.collect do |el|
        (el.is_a?(Symbol) && el.to_s.end_with?('?')) ? nil : el
      end
      @root.registerTSet(tset, pat)
      # seed tset which already stored data
      find(pattern).each do |t|
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
    
    # Return a set of tuples which match +pattern+. Pattern is
    # a tuples of the same length this store is configured for
    # where any non-nil element is matched directly and any
    # nil element is considered a wildcard.
    #
    def find(pattern)
      seta = []
      allWildcards = true
      @length.times do |i|
        if (item = pattern[i])
          allWildcards = false
          res = @index[i][item]
          #puts "res: index #{i}, res: #{res.inspect}"
          seta << res if res  # only add if non-nil
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