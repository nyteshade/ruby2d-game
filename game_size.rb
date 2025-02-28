module Game
  Size = Struct.new(:width, :height) do
    def initialize(width = 0, height = 0)
      super
    end

    def w = self.width
    def h = self.height
    def w=(value); self.width = value; end
    def h=(value); self.height = value; end

    def center = Point[self.width / 2, self.height / 2]

    def coordinates = [w, h]

    def to_s = "<Game::Size w=#{w} h=#{h}>"
  end
end
