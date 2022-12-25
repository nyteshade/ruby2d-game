# frozen_string_literal: true

require 'ruby2d'

# Patch Tileset so that we can access tile width and height values
# as well as the tile_definitions should we need to verify data
module Ruby2D
  class Tileset
    attr_accessor :tile_width, :tile_height, :tile_definitions, :path, :tiles
  end
end

# Original Class Methods
$orig_methods = {}
$array_append_listeners = {append:[]}

(Array.instance_methods - Object.instance_methods).each do |key|
  $orig_methods[Array] ||= {}
  $orig_methods[Array][key] = Array.instance_method key
end

# Add the ability to randomly choose an item from any array
class Array
  def self.add_listener(*_, &block)
    return unless block_given?

    $array_append_listeners[:append].append(block)
  end

  def append(*args)
    $array_append_listeners[:append].each do |callback|
      callback.call(self, *args)
    end
    $orig_methods[Array][:append].bind(self).call(*args)
  end

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
