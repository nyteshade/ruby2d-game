# frozen_string_literal: true

require 'ruby2d'

# Patch Tileset so that we can access tile width and height values
# as well as the tile_definitions should we need to verify data
module Ruby2D
  class Tileset
    attr_accessor :tile_width, :tile_height, :tile_definitions, :path, :tiles
  end
end

# Add the ability to randomly choose an item from any array
class Array
  def choose_one
    choice = rand(0...length)
    self[choice]
  end
end

def true?(value)
  ![false, 0, '0', 'f', 'F', 'false', 'FALSE', 'off', 'OFF'].include? value
end

def false?(value)
  !true? value
end

# Methods that expect self.props within which to store a :passable
# boolish property.
module Passable
  def ensure_passable_exists(value = true)
    return unless props

    props[:passable] = value
  end

  def passable
    false unless props
    false unless props.has_key? :passable
    props.fetch(:passable)
  end

  def passable=(value)
    return unless props

    props.store(:passable, value)
  end
end
