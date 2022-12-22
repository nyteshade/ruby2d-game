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
  attr_reader :metadata

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
    @tileset.set_tile(tile_name, [{ x: x * tile_width, y: y * tile_height }])
  end

  def metadata=(metadata_defs)
    defs = metadata_defs if metadata_defs.is_a? Array
    defs = [] unless metadata_defs

    @metadata = {}
    @tileset.clear_tiles

    defs.each do |tile|
      @metadata[tile.name] = tile
      @tileset.define_tile(tile.name, tile.x, tile.y)
      tile.tileset = @tileset unless tile.tileset
    end
  end
end
