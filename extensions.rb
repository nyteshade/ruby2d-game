# frozen_string_literal: true

require 'ruby2d'

# Patch Tileset so that we can access tile width and height values
# as well as the tile_definitions should we need to verify data
module Ruby2D
  class Tileset
    attr_accessor :tile_width, :tile_height, :tile_definitions
  end
end
