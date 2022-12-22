# frozen_string_literal: true

require 'ruby2d'

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

# Define new MapTile struct to hold properties for a given map tile.
# These would also include a
MapTile = Struct.new(:name, :x, :y, :z, :props, :tileset) do
  include Ruby2D::Renderable
  include Passable

  def initialize(name, x, y, z = 0, props = { passable: true }, tileset = nil)
    super
  end

  def to_s
    "<MapTile id=#{object_id} sym=#{name} props=#{props}>"
  end
end
