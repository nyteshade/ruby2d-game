require 'ruby2d/core' unless defined? Ruby2D
require_relative 'game_point' unless defined? Game::Point

module Game
  Tile = Struct.new(:name, :position, :passable, :props, :tileset) do
    include Ruby2D::Renderable

    def x = position.x
    def y = position.y
    def z = position.z

    def x=(value); position.x = value; end
    def y=(value); position.y = value; end
    def z=(value); position.z = value; end

    def initialize(name, position = Point.new, passable = true, props = { }, tileset = nil)
      super
    end

    def allows_passage?
      # First check if props exists and has a passable property defined
      if props && !props[:passable].nil?
        # If props.passable is defined (true or false), use that value
        return props[:passable]
      end

      # Otherwise, fall back to the tile's default passable value
      # If passable is nil, return false as specified
      return passable == true
    end

    def draw(position = nil)
      return unless tileset

      tileset.draw name, (position || self.position)
    end

    def to_s
      path = nil

      if tileset && (tileset.respond_to? 'path')
        path = File.basename(tileset&.path) unless tileset.nil?
      else
        path = 'n/a'
      end

      "<Tile id=#{object_id} sym=#{name} pos=#{x},#{y},#{z} passable=#{passable} props=#{props} tileset=#{path}>"
    end
  end
end
