# frozen_string_literal: true

require 'ruby2d'
require_relative 'map_tiles'

# This represents a map used in the game. It has helper methods and properties
# to identify what something is and
class Map
  attr_accessor :width, :height, :depth, :layers, :tileset, :actors, :tile

  def initialize(width, height, depth = 1, tileset = nil)
    @width = Integer(width)
    @height = Integer(height)
    @depth = Integer(depth)
    @layers = []
    @dirty = []

    @tile = Array.new(depth) { Array.new(height) { Array.new(width) } }

    self.actors = []
    self.tileset = tileset

    (0...depth).each do |z|
      @layers[z] = []
      @dirty[z] = []
      (0...width).each do |x|
        (0...height).each do |y|
          index = index_for(x, y)
          @layers[z][index] = ''
          @dirty[z][index] = true
        end
      end
    end
  end

  def define_map(&block)
    return unless block_given?

    (0...depth).each do |z|
      (0...height).each do |y|
        (0...depth).each do |x|
          tile = block.call @tile, x, y, z
          if tile.nil?
            tile = MapTile.new(:blank, x, y, z, { passable: true }, @tileset)
          elsif tile.is_a?(Symbol) && !@tileset.nil? && @tileset.is_a?(MapTiles)
            if @tileset.metadata.has_key?(tile)
              tile = @tileset.metadata[tile].dup
              tile.x = x
              tile.y = y
              tile.z = z
            end
          end
          @tile[z][y][x] = tile
        end
      end
    end
  end

  def index_for(x, y)
    (@width * y) + x
  end

  def dirty(x, y, z = 0)
    @dirty[z][index_for(x, y)] = true
  end

  def dirty_all_for(x, y)
    (0...depth).each do |z|
      @dirty[z][index_for(x, y)] = true
    end
  end

  def dirty_all
    (0...depth).each do |z|
      (0...width).each do |x|
        (0...height).each do |y|
          @dirty[z][index_for x, y] = true
        end
      end
    end
  end

  def clear(x, y, z = 0)
    @dirty[z][index_for(x, y)] = false
  end

  def clear_all_for(x, y)
    (0...depth).each do |z|
      @dirty[z][index_for(x, y)] = false
    end
  end

  def clear_all
    (0...depth).each do |z|
      (0...width).each do |x|
        (0...height).each do |y|
          @dirty[z][index_for x, y] = false
        end
      end
    end
  end

  def dirty?(x, y, z = 0)
    @dirty[z][index_for(x, y)] == true
  end

  def clear?(x, y, z = 0)
    @dirty[z][index_for(x, y)] == false
  end

  def draw_tile(tile)
    use_tileset = tile.map_tiles || tileset

    use_tileset.draw(tile.sprite, tile.x, tile.y) if tile && use_tileset
  end

  def actor_can_move?(actor, direction)
    case direction
    when 'left'
      return false if (actor.x - 1).negative?

      tiles = elements_at(actor.x - 1, actor.y).filter do |tile|
        next unless tile

        tile.passable == false
      end
      return false if tiles.length.positive?
    when 'right'
      return false if (actor.x + 1) >= width

      tiles = elements_at(actor.x + 1, actor.y).filter do |tile|
        next unless tile

        tile.passable == false
      end
      return false if tiles.length.positive?
    when 'up'
      return false if (actor.y - 1).negative?

      tiles = elements_at(actor.x, actor.y - 1).filter do |tile|
        next unless tile

        tile.passable == false
      end
      return false if tiles.length.positive?
    when 'down'
      return false if (actor.y + 1) >= height

      tiles = elements_at(actor.x, actor.y + 1).filter do |tile|
        next unless tile

        tile.passable == false
      end
      return false if tiles.length.positive?
    end
    true
  end

  def elements_at(x, y, z = nil)
    elements = []

    (0...layers.length).each do |mz|
      (0...height).each do |my|
        (0...width).each do |mx|
          next unless x == mx && y == my
          next if z && z != mz

          symbol = @layers[mz][index_for(mx, my)]
          elements.append(tileset.metadata[symbol]) unless symbol.empty?
        end
      end
    end

    actors.each do |actor|
      elements.append(actor) if actor.x == x && actor.y == y
    end

    elements
  end

  def add_actor(actor)
    actor.map_tiles = @tileset unless actor.map_tiles
    actors.append(actor)
    dirty(actor.x, actor.y, actor.z)
  end

  def remove_actor(actor)
    actors.delete_if do |element|
      if element == actor
        dirty(actor.x, actor.y)
        true
      else
        false
      end
    end
  end

  def out_of_bounds?(x, y, z = 0)
    if x < 0 || x >= width
      true
    elsif y < 0 || y >= height
      true
    elsif z < 0 || z >= depth
      true
    else
      false
    end
  end

  def relative_grid(x, y, z = 0, size = 1)
    grid = []

    (-size...size + 1).each do |rz|
      next unless z + rz >= 0

      (-size...size + 1).each do |ry|
        (-size...size + 1).each do |rx|
          nx, ny, nz = x + rx, y + ry, z + rz
          oob = out_of_bounds? nx, ny, nz
          element = oob ? nil : elements_at(nx, ny)
          grid[rz] ||= Array.new((size * 2) + 1) { Array.new((size * 2) + 1) }

          puts "(#{x} + #{rx}, #{y} + #{ry}, #{z} + #{rz}) #{element}"

          unless element.nil?
            element = element.reduce(nil) do |_, c|
              if c.respond_to?(:z) && z == nz
                c
              end
              nil
            end
          end

          grid[rz][ry + size][rx + size] = oob ? :out_of_bounds : (element || :empty)
        end
      end
    end

    grid
  end

  def move_actor(tile, direction, amount = 1)
    (0...depth).each do |z|
      dirty(tile.x, tile.y, z)
    end

    case direction
    when 'left'
      tile.x = tile.x - amount if tile.x - amount >= 0
    when 'right'
      tile.x = tile.x + amount if tile.x + amount < @width
    when 'up'
      tile.y = tile.y - amount if tile.y - amount >= 0
    when 'down'
      tile.y = tile.y + amount if tile.y + amount < @height
    else
      puts 'Unknown key'
    end
  end

  def draw
    return unless tileset

    (0...depth).each do |z|
      (0...width).each do |x|
        (0...height).each do |y|
          index = index_for(x, y)
          sprite = @layers[z][index]

          next if sprite.empty?

          if dirty?(x, y, z)
            tileset.draw(sprite, x, y)
            clear(x, y, z)
          end
        end
      end
    end

    @actors.each do |actor|
      actor.draw if dirty?(actor.x, actor.y, actor.z)
    end
  end

  def to_s
    "<Map tile_counts=#{width},#{height},#{depth} actors=#{@actors.length}>"
  end

  def inspect() = to_s
end
