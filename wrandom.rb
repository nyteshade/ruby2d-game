# frozen_string_literal: true

module WeightedRandom
  WRItem = Struct.new(:value, :weight, :next, :set) do
    def initialize(value, weight = 1.0, set = nil)
      super
    end

    def self.from_array(array, weight: 1.0)
      return [] unless array.is_a? Array

      items = []
      array.each do |element|
        items.append(WRItem[element, weight])
      end

      items
    end

    def self.from(*args)
      new(*args)
    end

    def to_s
      "Item:#{value} (#{weight})"
    end

    def inspect
      to_s
    end
  end

  # Weighted Randoms allow you to choose from a list, randomly, but respecting
  # the chance that some results are more likely to appear than others.
  class WRandom
    attr_accessor :items

    def initialize(items = [])
      @random = Random.new(Random.new_seed)
      @items = items || []
      @total = 0.0

      @items.each do |item|
        item.set = self
      end

      calc_totals
    end

    def to_s
      "<WRandom items=#{items.length} total=#{@total}>"
    end

    def inspect
      to_s
    end

    def calc_totals
      max = 0.0

      @items.each do |item|
        max += item.weight
      end

      @total = max
    end

    def add(*items)
      puts WRandom.normalize_args(1.0, *items)
      @items += WRandom.normalize_args(1.0, *items)
      calc_totals
    end

    def one
      choice = @random.rand(0.0...@total)
      current = 0.0
      chosen_item = nil

      @items.each do |item|
        current += item.weight

        next unless choice <= current

        chosen_item = item
        break
      end

      chosen_item = chosen_item&.next&.one unless chosen_item&.next.nil?
      chosen_item&.value
    end

    def some(count: 3)
      results = []

      (0...count).each do
        results.append(one)
      end

      results
    end

    def add_range(from = 1, to = 10, weighing = 1.0)
      (from..to).each do |number|
        @items.append(WRItem[number, weighing])
      end

      calc_totals
      self
    end

    def self.item(*args)
      WRItem.new(*args)
    end

    def self.from(*args)
      new(*args)
    end

    def self.normalize_args(default_weight, *args)
      list = []

      if args.length == 1
        if args.first.is_a? Array
          args = [*args.first]
        elsif !args.first.is_a? String
          args = Array(args.first)
        end
      end

      args.each do |item|
        if item.is_a? Array
          list.append(WRItem[item[0], item[1] || default_weight])
        elsif (item.respond_to? :weight) && (item.respond_to? :value)
          list.append(item)
        else
          list.append(WRItem[item, default_weight])
        end
      end

      list
    end

    def self.range(from = 0, to = 10, weighing = 1.0)
      new.add_range(from, to, weighing)
    end

    def self.roll(count = 1, sides = 6, repeat = 1, drop_lowest: false, individual_values: false)
      dice = WRandom.new
      results = []

      dice.add_range(1, sides, 1000)

      (0...repeat).each do |i|
        set = dice.some(count:)
        results += set
      end

      if individual_values
        results.sort
        results.shift if drop_lowest
      else
        results = results.reduce(0) { |p, c| p + c }
      end

      results
    end
  end
end
