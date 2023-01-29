module Game
  Point = Struct.new(:x, :y, :z) do
    def initialize(x = 0, y = 0, z = 0)
      super
    end

    def coordinates
      [x, y, z]
    end

    def to_s = "<Game::Point x=#{x} y=#{y} z=#{z}>"
  end
end
