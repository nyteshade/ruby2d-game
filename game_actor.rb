require 'ruby2d/core' unless defined? Ruby2D

module Game
  class Actor < Game::Tile
    include Ruby2D::Renderable

    def initialize(name, position, passable = false, props = { }, tileset = nil)
      super
    end

    def x = position.x
    def y = position.y
    def z = position.z
    def x=(new_x); position.x = new_x; end
    def y=(new_y); position.y = new_y; end
    def z=(new_z); position.z = new_z; end

    def player? = false

    def to_s =
      "<Actor id=#{object_id} symbol=#{name} pos=#{position} props=#{props} map_tiles=#{tileset}>"
  end

end
