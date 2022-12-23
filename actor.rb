# frozen_string_literal: true

require 'ruby2d'
require_relative 'map_tile'

Actor = Struct.new(:sprite, :x, :y, :z, :props, :map_tiles) do
  #include Ruby2D::Renderable
  include Passable

  def initialize(sprite, x, y, z = 0, props = { passable: false }, map_tiles = nil)
    super
  end

  def draw
    return unless map_tiles

    width = map_tiles.tileset.tile_width
    height = map_tiles.tileset.tile_height
    map_tiles.tileset.set_tile(sprite, [{ x: x * width, y: y * height }])
  end

  def to_s
    "<Actor id=#{object_id} sprite=#{sprite} pos=#{x},#{y},#{z} props=#{props} map_tiles=#{map_tiles}>"
  end

  def inspect() = to_s
end
