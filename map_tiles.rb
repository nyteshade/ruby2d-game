# frozen_string_literal: true

require 'ruby2d'
require_relative 'extensions'

# Contains a reference to the Tileset instance for these map tiles as well as
# some handy reference data such as the number of tiles wide and tall the set
# is. Additionally a convenient way to map tile names and additional metadata
# is provided through the MapTile struct instances. These are stored as an array
# of MapTile structs in the metadata property. Anytime this value is set, all
# known map tiles are cleared, and then re-setup for use.
class MapTiles
  attr_accessor :width, :height
  attr_reader :metadata, :tileset

  def to_s
    "<MapTiles path=#{File.basename @tileset.path} size=#{width},#{height} tile_size=#{tile_width},#{tile_height}>"
  end

  def inspect() = to_s

  def initialize(...)
    @tileset = Tileset.new(...)

    self.width = @tileset.width / tile_width
    self.height = @tileset.height / tile_height
  end

  def tile_width
    @tileset.tile_width
  end

  def tile_height
    @tileset.tile_height
  end

  def draw(tile_name, x, y)
    unless @tileset.tile_definitions.key? tile_name
      puts "@tileset #{@tileset.object_id} missing #{tile_name}"
    end
    return unless @tileset && (@tileset.tile_definitions.key? tile_name)

    @tileset.set_tile(tile_name, [{ x: x * tile_width, y: y * tile_height }])
  end

  def tileset=(value)
    case value
    when MapTiles
      @tileset = value.tileset
    when Tileset
      @tileset = value
    end
  end

  def metadata=(metadata_defs)
    defs = nil
    defs = metadata_defs if metadata_defs.is_a? Array
    defs = [] unless metadata_defs
    return unless defs

    @metadata = {}
    #@tileset.clear_tiles

    defs.each do |tile|
      @metadata[tile.name] = tile
      @tileset.define_tile(tile.name, tile.x, tile.y)
      tile.tileset = @tileset unless tile.tileset
    end
  end

  def set_sequential_metadata(metadata_defs, passable: true, tileset: nil)
    defs = nil
    defs = metadata_defs if metadata_defs.is_a? Array
    defs = [] unless metadata_defs

    return unless defs

    x = -1
    y = 0

    defs = defs.map do |element|
      compatible =
        element &&
        (
          (element.is_a? String) ||
          (element.is_a? Symbol) ||
          (element.is_a? Array)
        )
      next unless compatible

      if x + 1 >= width
        x = 0
        y += 1
      else
        x += 1
      end

      sym = element.to_sym unless element.is_a? Array
      props = { passable: }

      if element.is_a? Array
        sym = element.first.to_sym
        props = { passable: element[1] }
      end

      MapTile[sym, x, y, 0, props, tileset]
    end

    puts defs

    self.metadata = defs
  end
end
