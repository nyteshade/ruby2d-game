# frozen_string_literal: true

require 'ruby2d'

require_relative 'game_lib'
require_relative 'wrandom'

include Game
include WeightedRandom

$use_biome = if ENV.has_key?("biome") then ENV["biome"].to_sym else :snow end
$use_level = if ENV.has_key?("level") then ENV["level"].to_sym else :light end
$use_scale = if ENV.has_key?("scale") then ENV["scale"].to_f else 1.0 end

$map = Map::from_tmx "assets/tiled/Sample.tmx"
$map_tiles = $map.tileset

# Initialize Actors
$player = Actor[:female_mage, Point[0,1,1]]
$monster = Actor[:vampire, Point[11,5,1]]

$map.add_actor($player)
$map.add_actor($monster)
