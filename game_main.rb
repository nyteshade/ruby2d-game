# frozen_string_literal: true

require 'ruby2d'

require_relative 'extensions'
require_relative 'game_lib'
require_relative 'game_setup'

include Game

$use_biome = :sand
$use_level = :light

$player = Actor[:female_mage, Point[0,0]]
$monster = Actor[:vampire, Point[12,5]]

@label = Text.new(
  'FPS: ',
  x: 500, y: 10,
  font: 'assets/fonts/Gintronic-Regular.otf',
  size: 20,
  color: 'white',
  rotate: 0,
  z: 10
)

@label2 = Text.new(
  'Ticks: ',
  x: 500, y: 30,
  font: 'assets/fonts/Gintronic-Regular.otf',
  size: 20,
  color: 'white',
  rotate: 0,
  z: 10
)

# Initialize Map
$map = Map.new(20, 15, 2, $map_tiles)
$map.each_tile_of($map.data, only_z: 0) do |position, _|
  x, y, z = position.coordinates
  symbol = $biomes[$use_biome][$use_level][:passable].choose_one
  obstacle = nil

  if rand(0...100) < 15
    obstacle = $biomes[$use_biome][$use_level][:trees].choose_one
  elsif rand(0...100) < 5
    obstacle = $biomes[$use_biome][$use_level][:mountains].choose_one
  end

  tile = $map_tiles[symbol]
  $map[x, y, z] = tile
  unless obstacle.nil?
    $map[x, y, z + 1] = $map_tiles[obstacle]
  end
end

$map.add_actor($player)
$map.add_actor($monster)

# Define what happens when a specific key is pressed.
# Each keypress influences on the  movement along the x and y axis.
on :key_down do |event|
  $map.move_actor($player, event.key, 1) if $map.actor_can_move? $player, event.key
end

@ticks = 0
@total_ticks = 0

update do
  @ticks = @ticks.to_i + 1

  $map.draw

  if (@ticks % 60).zero?
    @ticks = 0
    @total_ticks = @total_ticks + 1

    enemy_direction = %w[left up right down][rand(0...4)]
    if $map.actor_can_move? $monster, enemy_direction
      $map.move_actor($monster, enemy_direction, 1)
    end

    unless @shown
      puts 'Showing player elements ['
      puts $map.elements_at($player.x, $player.y)

      puts "]\nShowing monster elements ["
      puts $map.elements_at($monster.x, $monster.y)
      puts ']'
      @shown = true
    end
  end

  #$map.actors.each(&:draw)

  @label.text = "FPS: #{Integer(Window.get(:fps))}"
  @label2.text = "Ticks: #{@total_ticks}"
end

show
