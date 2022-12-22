# frozen_string_literal: true

require 'ruby2d'
require_relative 'map_tile'

Actor = Struct.new(:sprite, :x, :y, :z, :props) do
  include Ruby2D::Renderable
  include Passable

  def initialize(sprite, x, y, z = 0, props = { passable: false })
    super
  end

  def to_s
    "<Actor id=#{object_id} sprite=#{sprite} pos=#{x},#{y},#{z} props=#{props}>"
  end
end
