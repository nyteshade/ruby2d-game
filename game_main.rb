# frozen_string_literal: true

require 'ruby2d'

require_relative 'extensions' unless defined?($extensions_complete)
require_relative 'game_lib' unless defined?(Game)
require_relative 'game_setup' unless defined?($setup_complete)

include Game

# provide some auto way of handling it when scale increases
# right now, we need to manually double the resolution of the
# window in order to get a scale 2 with the same number of
# tiles
set width: (640 * $use_scale), height: (480 * $use_scale)

@label = shadowed_text("FPS  : ", Point[500 * $use_scale,10])
@label2 = shadowed_text("Ticks: ", Point[500 * $use_scale, 30])
@label3 = shadowed_text("Total: ", Point[500 * $use_scale, 50])

# Define what happens when a specific key is pressed.
# Each keypress influences on the  movement along the x and y axis.
on :key_down do |event|
  $map.move_actor($player, event.key, 1) if $map.actor_can_move? $player, event.key

  case event.key
    # Add this to a key press handler for testing
  when 'd'  # Debug key
    puts "Animation debug:"
    test_tile = $map[$player.x, $player.y]

    if test_tile
      puts "Checking tile at player location:"
      puts "Is animated: #{test_tile.animated?}"
      puts "Current display: #{test_tile.current_display_name}"
      puts "Is dirty: #{$map.dirty?($player.x, $player.y)}"

      if test_tile.animated?
        test_tile.print_animation_sequence
      end
    end

    # Also check for any animated tiles in viewport
    animated_count = 0
    $map.visible.height.times do |y|
      $map.visible.width.times do |x|
        vx = $map.visible.x + x
        vy = $map.visible.y + y
        tile = $map[vx, vy, type = :tile]
        if tile && tile.animated?
          animated_count += 1
        end
      end
    end
    puts "Animated tiles in viewport: #{animated_count}"

  when 'e'
    command_enter event, $map, $player

  when 'r'
    puts "Actors"
    $map.actors.each do |actor|
      puts actor
    end
    puts "Elements at Player location"
    puts $map.elements_at $player.x, $player.y
    puts "Drawing map"
    $map.draw

  when 'q'
    exit!
  end
end

@ticks = 0
@total_ticks = 0

update do
  @ticks = @ticks.to_i + 1

  if $state[:tile_held_open].is_a? TileHeldOpen
    tho = $state[:tile_held_open]

    unless tho.is_opened?
      if @total_ticks - tho[:cur_ticks].to_i >= tho[:max_ticks].to_i
        tho.close
      end
    end
  end

  # Update animations for visible tiles
  $map.update_animations
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
