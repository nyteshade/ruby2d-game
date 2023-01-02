# frozen_string_literal: true

require 'ruby2d'

$use_biome = :sand
$use_level = :light

require_relative 'extensions'
require_relative 'map'
require_relative 'map_tiles'
require_relative 'map_tile'
require_relative 'actor'
require_relative 'bnk_setup'

$player = Actor.new(:female_mage, 0, 0)
$monster = Actor.new(:vampire, 12, 5)

@label = Text.new(
  'FPS: ',
  x: 500, y: 10,
  font: 'assets/fonts/Gintronic-Regular.otf',
  size: 20,
  color: 'white',
  rotate: 0,
  z: 10
)

# Initialize Map
@map = Map.new(20, 15, 2, $map_tiles)
(0...(@map.tiles_x)).each do |x|
  (0...(@map.tiles_y)).each do |y|
    @map.layers[0][(@map.tiles_x * y) + x] =
      $biomes[$use_biome][$use_level][:passable].choose_one
    if rand(0...100) < 15
      @map.layers[1][(@map.tiles_x * y) + x] =
        $biomes[$use_biome][$use_level][:trees].choose_one
    elsif rand(0...100) < 5
      @map.layers[1][(@map.tiles_x * y) + x] =
        $biomes[$use_biome][$use_level][:mountains].choose_one
    end
  end
end

@map.add_actor($player)
@map.add_actor($monster)

# Define what happens when a specific key is pressed.
# Each keypress influences on the  movement along the x and y axis.
on :key_down do |event|
  @map.move_actor($player, event.key, 1) if @map.actor_can_move? $player, event.key
end

@ticks = 0
@shown = false

update do
  @ticks = @ticks.to_i + 1

  @map.draw

  if (@ticks % 60).zero?
    @ticks = 0

    enemy_direction = %w[left up right down][rand(0...4)]
    if @map.actor_can_move? $monster, enemy_direction
      @map.move_actor($monster, enemy_direction, 1)
    end

    unless @shown
      puts 'Showing player elements ['
      puts @map.elements_at($player.x, $player.y)

      puts "]\nShowing monster elements ["
      puts @map.elements_at($monster.x, $monster.y)
      puts ']'
      @shown = true
    end
  end

  @map.actors.each(&:draw)

  @label.text = "FPS: #{Integer(Window.get(:fps))}"
end

show
