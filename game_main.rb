# frozen_string_literal: true

require 'ruby2d'

require_relative 'extensions'
require_relative 'game_lib'
require_relative 'game_setup'

include Game

# provide some auto way of handling it when scale increases
# right now, we need to manually double the resolution of the
# window in order to get a scale 2 with the same number of
# tiles
set width: (640 * $use_scale), height: (480 * $use_scale)

@label = shadowed_text("FPS  : ", Point[500 * $use_scale,10])
@label2 = shadowed_text("Ticks: ", Point[500 * $use_scale, 30])

# Define what happens when a specific key is pressed.
# Each keypress influences on the  movement along the x and y axis.
on :key_down do |event|
  $map.move_actor($player, event.key, 1) if $map.actor_can_move? $player, event.key

  case event.key
  when 'e'
    tiles = $map.elements_at($player.x, $player.y)
    tiles.each do |tile|
      next unless tile.is_a? Game::Tile

      conditions = [
        tile.props.has_key?(:enterable),
        tile.props.has_key?(:destination_map),
        tile.props.has_key?(:destination_x),
        tile.props.has_key?(:destination_y),
        tile.props.has_key?(:destination_z)
      ]
      if conditions.all? and tile.props[:enterable]
        dmap = tile.props[:destination_map]
        next unless dmap.size > 0

        dpos = Point[
          tile.props[:destination_x],
          tile.props[:destination_y],
          tile.props[:destination_z]
        ]

        next unless dmap.ends_with?(".tmx") or dmap.ends_with?(".tmj")

        if dmap.ends_with?(".tmx")
          dmap = Map.from_tmx(dmap)
        else
          dmap = Map.from_tmj(dmap)
        end

        if dmap
          dest_elements = dmap.elements_at(dpos)
          passable = true
          dest_elements.each do |element|
            unless element.passable
              passable = false
              break
            end
          end

          if passable
            $map = dmap
            $player.position = dpos
            (Ruby2D::Window.get :window).clear
          end
        end
      end
    end
  when 'q'
    exit!
  end
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
  end

  #$map.actors.each(&:draw)

  @label.set_text "FPS: #{Integer(Window.get(:fps))}"
  @label2.set_text "Ticks: #{@total_ticks}"
end

show
