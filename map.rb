# frozen_string_literal: true

require 'ruby2d'
require_relative 'map_tiles'

# This represents a map used in the game. It has helper methods and properties
# to identify what something is and
class Map
  attr_accessor :tiles_x, :tiles_y, :tiles_z, :layers, :tileset, :actors

  def initialize(width, height, depth = 1, tileset = nil)
    @tiles_x = Integer(width)
    @tiles_y = Integer(height)
    @tiles_z = Integer(depth)
    @layers = []
    @dirty = []

    self.actors = []
    self.tileset = tileset

    (0...tiles_z).each do |z|
      @layers[z] = []
      @dirty[z] = []
      (0...tiles_x).each do |x|
        (0...tiles_y).each do |y|
          index = index_for(x, y)
          @layers[z][index] = ''
          @dirty[z][index] = true
        end
      end
    end
  end

  def index_for(x, y)
    (@tiles_x * y) + x
  end

  def dirty(x, y, z = 0)
    @dirty[z][index_for(x, y)] = true
  end

  def dirty_all_for(x, y)
    (0...tiles_z).each do |z|
      @dirty[z][index_for(x, y)] = true
    end
  end

  def dirty_all
    (0...tiles_z).each do |z|
      (0...tiles_x).each do |x|
        (0...tiles_y).each do |y|
          @dirty[z][index_for x, y] = true
        end
      end
    end
  end

  def clear(x, y, z = 0)
    @dirty[z][index_for(x, y)] = false
  end

  def clear_all_for(x, y)
    (0...tiles_z).each do |z|
      @dirty[z][index_for(x, y)] = false
    end
  end

  def clear_all
    (0...tiles_z).each do |z|
      (0...tiles_x).each do |x|
        (0...tiles_y).each do |y|
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
      return false if (actor.x + 1) >= tiles_x

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
      return false if (actor.y + 1) >= tiles_y

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
      (0...tiles_y).each do |my|
        (0...tiles_x).each do |mx|
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

  def move_actor(tile, direction, amount = 1)
    (0...tiles_z).each do |z|
      dirty(tile.x, tile.y, z)
    end

    case direction
    when 'left'
      tile.x = tile.x - amount if tile.x - amount >= 0
    when 'right'
      tile.x = tile.x + amount if tile.x + amount < @tiles_x
    when 'up'
      tile.y = tile.y - amount if tile.y - amount >= 0
    when 'down'
      tile.y = tile.y + amount if tile.y + amount < @tiles_y
    else
      puts 'Unknown key'
    end
  end

  def draw
    return unless tileset

    (0...tiles_z).each do |z|
      (0...tiles_x).each do |x|
        (0...tiles_y).each do |y|
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
    "<Map tile_counts=#{tiles_x},#{tiles_y},#{tiles_z} actors=#{@actors.length}>"
  end

  def inspect() = to_s
end
