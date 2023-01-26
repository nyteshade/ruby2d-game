# frozen_string_literal: true

require 'ruby2d' unless defined?(Ruby2D)

require_relative 'game_lib' unless defined?(Game)
require_relative 'wrandom' unless defined?(WeightedRandom)

include Game
include WeightedRandom

$use_scale = if ENV.has_key?("scale") then ENV["scale"].to_f else 1.0 end

$map = Map::from_tmj "StarterIsland.tmj"
$map_tiles = $map.tileset

$win_tile_size = Size[
  (Window.get :width) / $map.tileset.tile_width,
  (Window.get :height) / $map.tileset.tile_height
]

$map.visible = Rect[$win_tile_size]

puts $win_tile_size

# Initialize Actors
$player = Player[:avatar, Point[$win_tile_size.w / 2, $win_tile_size.h / 2, 1]]
$monster = Actor[:ettin_0, Point[11,5,1]]

$map.add_actor($player)
$map.add_actor($monster)

$setup_complete = true
