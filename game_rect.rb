require_relative 'game_size' unless defined? Game::Size
require_relative 'game_point' unless defined? Game::Point

module Game
  Rect = Struct.new(:position, :size) do
    def initialize(size = Size[], position = Point[], or_x = nil, or_y = nil)
      self.size = size if size.is_a? Size
      self.position = position if position.is_a? Point

      if not self.size or not self.position
        if size.is_a? Numeric and position.is_a? Numeric
          self.size = Size[size, position]
          self.position = Point[]
        else
          self.size = Size[]
          self.position = Point[]
        end
      end
    end

    def x = position.x
    def y = position.y
    def width = size.width
    def height = size.height

    def x=(value) position.x = value; end
    def y=(value) position.y = value; end
    def width=(value) size.width = value; end
    def height=(value) size.height = value; end

    def top = position.y
    def left = position.x
    def bottom = position.y + size.height
    def right = position.x + size.width

    def coordinates = [x, y, width, height]
    def edges = [top, right, bottom, left]

    def contains(point)
      return false if point.nil? or point.is_a? Numeric

      return false if point.x < left
      return false if point.y < top
      return false if point.x >= right
      return false if point.y >= bottom

      return true
    end

    def translate(x_or_point, y = nil)
      x = x_or_point unless x_or_point.is_a? Point
      x = x_or_point.x if x_or_point.is_a? Point
      y = x_or_point.y if x_or_point.is_a? Point

      self.x += x
      self.y += y

      return self
    end

    def translate_to(x_or_point, y = nil)
      x = x_or_point unless x_or_point.is_a? Point
      x = x_or_point.x if x_or_point.is_a? Point
      y = x_or_point.y if x_or_point.is_a? Point

      self.x = x
      self.y = y

      return self
    end

    def to_s = "<Rect position=#{position.coordinates} size=#{size.coordinates} t,r,b,l=#{edges}>"
  end
end
