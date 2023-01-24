# frozen_string_literal: true

require 'ruby2d' unless defined?(Ruby2D)

require_relative 'game_lib' unless defined?(Game)
require_relative 'wrandom' unless defined?(WeightedRandom)

include Game
include WeightedRandom

$use_scale = if ENV.has_key?("scale") then ENV["scale"].to_f else 1.0 end

$map = Map::from_tmj "assets/tiled/Sample.tmj"
$map_tiles = $map.tileset

# Initialize Actors
$player = Actor[:female_mage, Point[0,1,1]]
$monster = Actor[:vampire, Point[11,5,1]]

$map.add_actor($player)
$map.add_actor($monster)

$setup_complete = true
