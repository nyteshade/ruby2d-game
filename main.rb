# frozen_string_literal: true

require 'ruby2d'

require_relative 'map'
require_relative 'map_tiles'
require_relative 'map_tile'
require_relative 'actor'

$player = Actor.new(:witch, 0, 0)
$monster = Actor.new(:gryphon, 1, 1)

$map_tiles = MapTiles.new(
  'assets/tileset/DungeonCrawl_ProjectUtumnoTileset_0.png', # 64 tiles wide, 48 tiles tall
  tile_width: 32,
  tile_height: 32
)

$map_tiles.metadata = [
  MapTile[:grass1, 0, 15],
  MapTile[:grass2, 1, 15],
  MapTile[:grass3, 2, 15],
  MapTile[:grass4, 3, 15],
  MapTile[:grass5, 4, 15],
  MapTile[:grass6, 5, 15],
  MapTile[:grass7, 6, 15],
  MapTile[:dirt1, 0, 14],
  MapTile[:dirt2, 1, 14],
  MapTile[:dirt3, 2, 14],
  MapTile[:dirt4, 3, 14],
  MapTile[:dirt5, 4, 14],
  MapTile[:dirt6, 5, 14],
  MapTile[:dirt7, 6, 14],
  MapTile[:patchy_grass1, 0, 13],
  MapTile[:patchy_grass2, 1, 13],
  MapTile[:patchy_grass3, 2, 13],
  MapTile[:patchy_grass4, 3, 13],
  MapTile[:patchy_grass5, 4, 13],
  MapTile[:patchy_grass6, 5, 13],
  MapTile[:patchy_grass7, 6, 13],
  MapTile[:sand1, 14, 13],
  MapTile[:sand2, 15, 13],
  MapTile[:sand3, 16, 13],
  MapTile[:sand4, 17, 13],
  MapTile[:sand5, 18, 13],
  MapTile[:sand6, 19, 13],
  MapTile[:sand7, 20, 13],
  MapTile[:sand8, 21, 13],
  MapTile[:tree1, 12, 18, 0, { passable: false }],
  MapTile[:tree2, 13, 18, 0, { passable: false }],
  MapTile[:tree3, 14, 18, 0, { passable: false }],
  MapTile[:tree4, 15, 18, 0, { passable: false }],
  MapTile[:tree5, 16, 18, 0, { passable: false }],
  MapTile[:tree6, 17, 18, 0, { passable: false }],
  MapTile[:witch, 2, 9],
  MapTile[:gryphon, 2, 2]
]

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
    @map.layers[0][(@map.tiles_x * y) + x] = "grass#{rand(1...7)}".to_sym
    if rand(0...100) < 10
      @map.layers[1][(@map.tiles_x * y) + x] = "tree#{rand(1...6)}".to_sym
    end
  end
end

@map.add_actor($player)
@map.add_actor($monster)

# Define what happens when a specific key is pressed.
# Each keypress influences on the  movement along the x and y axis.
on :key_down do |event|
  if @map.actor_can_move? $player, event.key
    @map.move_actor($player, event.key, 1)
  end
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
      puts @map.elements_at($player.x, $player.y)
      @shown = true
    end
  end

  @map.actors.each do |actor|
    @map.draw_tile(actor)
  end

  @label.text = "FPS: #{Integer(Window.get(:fps))}"
end

show
