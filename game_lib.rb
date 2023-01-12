require 'ruby2d'

module Game
  class Tiles < Ruby2D::Tileset
    attr_accessor(
      :tile_width, :tile_height, :tile_definitions,
      :path, :tiles, :metadata
    )

    def initialize(...)
      super

      self.metadata = {
        tiles: Array.new(height) { Array.new(width) },
        symbols: { }
      }
    end

    def [](x_or_symbol, y = 0, type = :tile)
      x = nil
      x = x_or_symbol unless x_or_symbol.is_a? Symbol

      if x_or_symbol.is_a? Symbol
        metadata[:symbols][x_or_symbol]
      else
        return nil unless metadata[:tiles][y][x]

        case type
        when :tile then metadata[:tiles][y][x]
        when :symbol then metadata[:tiles][y][x].name
        else nil
        end
      end
    end

    def []=(x, y, tile)
      return unless tile.is_a? Game::Tile

      method = Ruby2D::Tileset.instance_method(:define_tile).bind(self)

      method.call(tile.name, tile.x, tile.y)
      metadata[:tiles][y][x] = tile
      metadata[:symbols][tile.name] = metadata[:tiles][y][x]
    end

    def define_tile(name, x, y, rotate: nil, flip: nil)
      super

      tile = Tile[name.to_sym, Point[x,y]]
      metadata[:tiles][y][x] = tile
      metadata[:symbols][tile.name] = tile
    end

    def draw(symbol, *at)
      return unless symbol.is_a? Symbol

      if metadata[:symbols].has_key? symbol
        at = at.map do |point|
          point = Point[point.x, point.y] unless point.is_a? Point

          new_point = {
            x: point.x * tile_width * @scale,
            y: point.y * tile_height * @scale,
            z: point.z
          }

          new_point
        end

        set_tile(symbol, at)
      end
    end

    def set_sequential_definitions(metadata_defs, passable: true)
      defs = sym = nil
      defs = metadata_defs if metadata_defs.is_a? Array
      defs = [] unless metadata_defs

      return unless defs

      x = -1
      y = 0

      defs.each do |element|
        is_not_nil = !element.nil?
        is_a_string = element.is_a? String
        is_a_symbol = element.is_a? Symbol
        is_an_array = element.is_a? Array

        compatible = is_not_nil && [
          is_a_string,
          is_a_symbol,
          is_an_array
        ].any?

        next unless compatible

        if x + 1 >= width
          x = 0
          y += 1
        else
          x += 1
        end

        sym = element.to_sym unless element.is_a? Array

        if is_an_array
          sym = element.first.to_sym
          if element.size > 1
            passable = true? element[1]
          end
        end

        self[x,y] = Tile[sym, Point[x, y], passable, {}, self]
      end
    end

    def image_width()
      @width
    end

    def image_height()
      @height
    end

    def width()
      @width / tile_width
    end

    def height()
      @height / tile_height
    end
  end

  Point = Struct.new(:x, :y, :z) do
    def initialize(x = 0, y = 0, z = 0)
      super
    end

    def coordinates
      [x, y, z]
    end

    def ==(other)
      return false unless other.respond_to? :x
      return false unless other.respond_to? :y
      return false unless other.respond_to? :z
      return false unless x == other.x && y == other.y && z == other.z
      true
    end

    def to_s() = "<Game::Point x=#{x} y=#{y} z=#{z}>"
    def inspect() = to_s
  end

  Tile = Struct.new(:name, :position, :passable, :props, :tileset) do
    include Ruby2D::Renderable

    def x() = position.x
    def y() = position.y
    def z() = position.z

    def x=(value); position.x = value; end
    def y=(value); position.y = value; end
    def z=(value); position.z = value; end

    def initialize(name, position = Point.new, passable = true, props = { }, tileset = nil)
      super
    end

    def draw(position = nil)
      return unless tileset

      tileset.draw name, position || self.position
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

    def inspect() = to_s
  end

  class Actor < Game::Tile
    include Ruby2D::Renderable

    def initialize(name, position, passable = true, props = { }, tileset = nil)
      super
    end

    def to_s
      "<Actor id=#{object_id} symbol=#{name} pos=#{position} props=#{props} map_tiles=#{tileset}>"
    end

    def inspect() = to_s
  end

  Map = Struct.new(:width, :height, :depth, :tileset, :actors, :data) do
    def initialize(width, height, depth = 1, tileset = nil, actors = [], all_of_type: nil)
      self.actors = actors || []
      self.data = Array.new(depth) { Array.new(height) { Array.new(width) } }
      self.tileset = tileset
      self.tileset = nil unless tileset&.is_a? Game::Tiles

      set_default_tile = tileset && all_of_type && all_of_type.is_a?(Symbol)

      self.width = width
      self.height = height
      self.depth = depth

      default_tile = nil
      if set_default_tile && self.tileset[all_of_type]
        default_tile = self.tileset[all_of_type]
      end

      each_tile_of(self.data, :meta) do |point, _|
        next { tile: default_tile, dirty: false }
      end
    end

    def [](x, y, z = 0, type = :tile)
      case type
      when :tile then self.data[z][y][x][:tile]
      when :dirty then self.data[z][y][x][:dirty]
      when :actor
        any_actors = self.actors.filter do |actor|
          false unless actor.position == Point[x, y, z]
          true
        end
        nil unless any_actors.count > 0
        any_actors.first
      else nil
      end
    end

    def []=(x, y, z, new_tile)
      self.data[z][y][x][:tile] = new_tile
      self.data[z][y][x][:dirty] = true
    end

    def each_tile_of(multi_dim_array, result_type = :tile, only_z: nil, &block)
      return unless block_given?
      multi_dim_array = self.data unless multi_dim_array

      start_depth = only_z || 0
      end_depth = (only_z && (only_z + 1)) || depth

      (start_depth...end_depth).each do |z|
        (0...height).each do |y|
          (0...width).each do |x|
            result = block.call Point[x,y,z], self
            if result
              case result_type
              when :tile then multi_dim_array[z][y][x][:tile] = result
              when :dirty then multi_dim_array[z][y][x][:dirty] = result
              when :meta then multi_dim_array[z][y][x] = result
              else next
              end
            end
          end
        end
      end
    end

    def define_map(&block)
      return unless block_given?

      each_tile_of(data) do |position, map|
        x, y, z = position.coordinates
        tile = block.call @tileset, x, y, z

        received_tile_is_symbol = tile.is_a?(Symbol)
        tile_is_not_nil = !tile.nil?
        tileset_is_not_nil = !@tileset.nil?
        tileset_is_game_tiles = @tileset.is_a? Tiles
        tileset_has_symbol = @tileset.has_key?(tile)

        conditions = [
          received_tile_is_symbol,
          tile_is_not_nil,
          tileset_is_game_tiles,
          tileset_is_not_nil,
          tileset_has_symbol
        ]

        if tile.nil?
          Tile.new(:blank, position, true, {}, @tileset)
        elsif conditions.all?(true)
          tile = @tileset[tile].dup
          tile.position = position.dup
          tile
        end
      end
    end

    def dirty(x, y, z = nil)
      if z.nil?
        dirty_all_for x, y
      else
        self.data[z][y][x][:dirty] = true
      end
    end

    def dirty_all_for(x, y)
      (0...depth).each do |z|
        self.data[z][y][x][:dirty] = true
      end
    end

    def dirty_all
      (0...depth).each do |z|
        (0...width).each do |x|
          (0...height).each do |y|
            self.data[z][y][x][:dirty] = true
          end
        end
      end
    end

    def clear(x, y, z = nil)
      if z.nil?
        clear_all_for x, y
      else
        self.data[z][y][x][:dirty] = false
      end
    end

    def clear_all_for(x, y)
      (0...depth).each do |z|
        self.data[z][y][x][:dirty] = false
      end
    end

    def clear_all
      (0...depth).each do |z|
        (0...width).each do |x|
          (0...height).each do |y|
            self.data[z][y][x][:dirty] = false
          end
        end
      end
    end

    def dirty?(x, y, z = 0)
      self.data[z][y][x][:dirty] == true
    end

    def clear?(x, y, z = 0)
      self.data[z][y][x][:dirty] == false
    end

    def draw_tile(tile)
      return unless tile && tile.is_a?(Tile)

      tile.draw
    end

    def actor_can_move?(actor, direction)
      case direction
      when 'left'
        return false if (actor.x - 1).negative?

        tiles = elements_at(actor.x - 1, actor.y).filter do |tile|
          not_array = !tile.is_a?(Array)
          not_nil = !tile.nil?

          next unless [not_array, not_nil].all?

          tile.passable == false
        end
        return false if tiles.length.positive?
      when 'right'
        return false if (actor.x + 1) >= width

        tiles = elements_at(actor.x + 1, actor.y).filter do |tile|
          not_array = !tile.is_a?(Array)
          not_nil = !tile.nil?

          next unless [not_array, not_nil].all?

          tile.passable == false
        end
        return false if tiles.length.positive?
      when 'up'
        return false if (actor.y - 1).negative?

        tiles = elements_at(actor.x, actor.y - 1).filter do |tile|
          not_array = !tile.is_a?(Array)
          not_nil = !tile.nil?

          next unless [not_array, not_nil].all?

          tile.passable == false
        end
        return false if tiles.length.positive?
      when 'down'
        return false if (actor.y + 1) >= height

        tiles = elements_at(actor.x, actor.y + 1).filter do |tile|
          not_array = !tile.is_a?(Array)
          not_nil = !tile.nil?

          next unless [not_array, not_nil].all?

          tile.passable == false
        end
        return false if tiles.length.positive?
      end
      true
    end

    def elements_at(x, y, z = nil)
      elements = Array.new(depth) { Array.new }

      each_tile_of(data) do |position, _|
        dx, dy, dz = position.coordinates

        x_matches = x == dx
        y_matches = y == dy
        z_matches = z ? z == dz : true
        conditions = [x_matches, y_matches, z_matches]

        if conditions.all?
          elements[z.nil? ? 0 : dz] = self[dx, dy, dz]
        end
      end

      actors.each do |actor|
        not_nil = actor.nil?
        is_array = actor.is_a? Array

        next unless [not_nil, is_array].all?

        elements[z || 0].append(actor) if actor.x == x && actor.y == y
      end

      elements
    end

    def add_actor(actor)
      actor.tileset = self.tileset unless actor.tileset
      actors.append(actor)
      dirty(actor.x, actor.y)
    end

    def remove_actor(actor)
      actors.delete_if do |element|
        if element == actor
          dirty(actor.x, actor.y)
          true
        else
          false
        end
      end
    end

    def out_of_bounds?(x, y, z = 0)
      if x < 0 || x >= width
        true
      elsif y < 0 || y >= height
        true
      elsif z < 0 || z >= depth
        true
      else
        false
      end
    end

    def relative_grid(x, y, z = 0, size = 1)
      grid = []

      (-size...size + 1).each do |rz|
        next unless z + rz >= 0

        (-size...size + 1).each do |ry|
          (-size...size + 1).each do |rx|
            nx, ny, nz = x + rx, y + ry, z + rz
            oob = out_of_bounds? nx, ny, nz
            element = oob ? nil : elements_at(nx, ny)
            grid[rz] ||= Array.new((size * 2) + 1) { Array.new((size * 2) + 1) }

            puts "(#{x} + #{rx}, #{y} + #{ry}, #{z} + #{rz}) #{element}"

            unless element.nil?
              element = element.reduce(nil) do |_, c|
                if c.respond_to?(:z) && z == nz
                  c
                end
                nil
              end
            end

            grid[rz][ry + size][rx + size] = oob ? :out_of_bounds : (element || :empty)
          end
        end
      end

      grid
    end

    def move_actor(tile, direction, amount = 1)
      return unless tile && tile.is_a?(Game::Tile)

      dirty tile.x, tile.y
      old = tile.position.dup

      case direction
      when 'left'
        tile.x = tile.x - amount if tile.x - amount >= 0
      when 'right'
        tile.x = tile.x + amount if tile.x + amount < width
      when 'up'
        tile.y = tile.y - amount if tile.y - amount >= 0
      when 'down'
        tile.y = tile.y + amount if tile.y + amount < height
      else
        puts 'Unknown key'
      end

      #dirty tile.x, tile.y

      tile.position == old ? true : false
    end

    def draw
      return unless self.tileset

      each_tile_of(data) do |position, _|
        x, y, z = position.coordinates
        tile = self[x, y, z]

        next unless tile&.is_a? Tile

        tileset.draw tile.name, position if dirty?(x, y, z)
        clear x, y, z if dirty? x, y, z
      end

      actors.each do |actor|
        actor.draw
      end
    end

    def to_s
      "<Map tile_counts=#{width},#{height},#{depth} actors=#{@actors&.length}>"
    end

    def inspect() = to_s
  end
end
