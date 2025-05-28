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

# Define what happens when a specific key is pressed.
# Each keypress influences on the  movement along the x and y axis.
on :key_down do |event|
  if $map.actor_can_move? $player, event.key
    if $map.move_actor($player, event.key, 1)
      @needs_redraw = true
    end
  end

  case event.key
  when 'e'
    command_enter event, $map, $player
    @needs_redraw = true
    # Refresh animated tiles for new map
    @animated_tiles = $map.collect_animated_tiles
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
@needs_redraw = true
@last_time = Time.now
@animated_tiles = $map.collect_animated_tiles
puts "Found #{@animated_tiles.length} animated tiles on startup"

update do
  current_time = Time.now
  delta_time = current_time - @last_time
  @last_time = current_time
  
  @ticks = @ticks.to_i + 1
  frame_dirty = false

  # Update animations (only for visible tiles for performance)
  unless @animated_tiles.empty?
    @animated_tiles.each do |tile|
      next unless tile.animated?
      
      # update_animation now returns true if frame changed
      if tile.update_animation(delta_time)
        # Animation changed - just mark for redraw
        $map.dirty_all_for(tile.x, tile.y)
        frame_dirty = true
        puts "Animation frame changed for #{tile.name} at #{tile.x},#{tile.y} -> #{tile.current_frame}"
      end
    end
  end

  if (@ticks % 60).zero?
    @ticks = 0
    @total_ticks = @total_ticks + 1

    # Refresh animated tiles periodically as viewport may have changed
    @animated_tiles = $map.collect_animated_tiles

    enemy_direction = %w[left up right down][rand(0...4)]
    if $map.actor_can_move? $monster, enemy_direction
      if $map.move_actor($monster, enemy_direction, 1)
        frame_dirty = true
      end
    end
  end

  # Only redraw if something changed or forced redraw needed
  if @needs_redraw || frame_dirty
    $map.draw
    @needs_redraw = false
  end

  @label.set_text "FPS: #{Integer(Window.get(:fps))}"
  @label2.set_text "Ticks: #{@total_ticks}"
end

show
