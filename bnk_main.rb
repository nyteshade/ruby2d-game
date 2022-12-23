# frozen_string_literal: true

require 'ruby2d'

require_relative 'extensions'
require_relative 'map'
require_relative 'map_tiles'
require_relative 'map_tile'
require_relative 'actor'
require_relative 'bnk_setup'

$player = Actor.new(:female_mage, 0, 0, 0, { passable: false }, $npc_tiles)
$monster = Actor.new(:vampire, 12, 5, 0, { passable: false }, $npc_tiles)

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
    @map.layers[0][(@map.tiles_x * y) + x] = %i[green_noise grassy_hills].choose_one
    @map.layers[1][(@map.tiles_x * y) + x] = %i[grass_tree grass_evergreen grassy_mountain].choose_one if rand(0...100) < 10
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
