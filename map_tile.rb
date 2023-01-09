# frozen_string_literal: true

require 'ruby2d'
require_relative 'extensions'

# Define new MapTile struct to hold properties for a given map tile.
# These would also include a
MapTile = Struct.new(:name, :x, :y, :z, :props, :tileset) do
  include Ruby2D::Renderable
  include Passable

  attr_accessor :x, :y, :z

  def initialize(name, x, y, z = 0, props = { passable: true }, tileset = nil)
    super
  end

  def to_s
    path = nil

    if tileset && (tileset.respond_to? 'path')
      path = File.basename(tileset&.path) unless tileset.nil?
    else
      path = 'n/a'
    end

    "<MapTile id=#{object_id} sym=#{name} tileset_pos=#{x},#{y},#{z} props=#{props} tileset=#{path}>"
  end

  def inspect() = to_s
end
