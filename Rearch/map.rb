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

    def [](x_or_symbol, y, type = :tile)
      x = nil
      x = x_or_symbol unless x_or_symbol.is_a? Symbol

      if x_or_symbol.is_a? Symbol
        metadata.symbols[x_or_symbol]
      else
        case type
        when :tile then metadata.tiles[y][x]
        when :symbol then metadata.tiles[y][x].name
        else nil
        end
      end
    end

    def []=(x, y, tile)
      return unless tile.is_a? Game::Tile

      define_tile(tile.name, tile.x, tile.y)
      metadata.tiles[y][x] = tile
      metadata.symbols[tile.name] = metadata.tiles[y][x]
    end

    def define_tile(name, x, y, rotate: nil, flip: nil)
      super

      tile = Tile[name.to_sym, Point[x,y]]
      metadata.tiles[y][x] = tile
      metadata.symbols[tile.name] = tile
    end

    def draw(symbol, *at)
      return unless symbol.is_a? Symbol

      if metadata.symbols.has_key? symbol
        at = at.map do |point|
          new_point = point.dup
          new_point.x = point.x * tile_width * @scale
          new_point.y = point.y * tile_height * @scale
          new_point
        end

        set_tile(symbol, *at)
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
        compatible =
          element &&
            (
              (element.is_a? String) ||
                (element.is_a? Symbol) ||
                (element.is_a? Array)
            )
        next unless compatible

        if x + 1 >= width
          x = 0
          y += 1
        else
          x += 1
        end

        sym = element.to_sym unless element.is_a? Array

        if element.is_a? Array
          sym = element.first.to_sym
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
      false unless other.respond_to? :x
      false unless other.respond_to? :y
      false unless other.respond_to? :z
      false unless x == other.x && y == other.y && z == other.z
      true
    end

    def to_s() = "<Game::Point x=#{x} y=#{y} z=#{z}>"
    def inspect() = to_s
  end

  Tile = Struct.new(:name, :position, :passable, :props, :tileset) do
    include Ruby2D::Renderable

    def x() = point.x
    def y() = point.y
    def z() = point.z

    def x=(value); point.x = value; end
    def y=(value); point.y = value; end
    def z=(value); point.z = value; end

    def initialize(name, position = Point.new, passable = true, props = { }, tileset = nil)
      super
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

    def initialize(name, position, passable = true, props = { }, tileset)
      super
    end

    def draw
      # implement
    end

    def to_s
      "<Actor id=#{object_id} sprite=#{sprite} pos=#{x},#{y},#{z} props=#{props} map_tiles=#{map_tiles}>"
    end

    def inspect() = to_s
  end

  class Map
    attr_accessor :width, :height, :depth, :tileset, :actors, :data

    def initialize(width, height, depth = 1, tileset = nil, all_of_type = nil)
      actors = []
      self.data = Array.new(depth) { Array.new(height) { Array.new(width) } }

      tileset = nil unless tileset&.is_a? Game::Tiles
      set_default_tile = tileset && all_of_type && all_of_type.is_a?(Symbol)

      self.width = width
      self.height = height
      self.depth = depth
      self.tileset &&= tileset

      default_tile = nil
      if set_default_tile && self.tileset[all_of_type]
        default_tile = self.tileset[all_of_type]
      end

      each_tile_of(self.data, :meta) do |point, _|
        x, y, z = point.coordinates
        self.data[z][y][x] = { tile: default_tile, dirty: false }
      end
    end

    def [](x, y, z = 0, type = :tile)
      case type
      when :tile then self.data[z][y][x].tile
      when :dirty then self.data[z][y][x].dirty
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

    def each_tile_of(multi_dim_array, result_type = :tile, &block)
      return unless block_given?
      multi_dim_array = self.data unless multi_dim_array

      (0...depth).each do |z|
        (0...height).each do |y|
          (0...width).each do |x|
            result = block.call Point[x,y,z], self
            if result
              case result_type
              when :tile then multi_dim_array[z][y][x].tile = result
              when :dirty then multi_dim_array[z][y][x].dirty = result
              else next
              end
            end
          end
        end
      end
    end

    def define_map(&block)
      return unless block_given?

      (0...depth).each do |z|
        (0...height).each do |y|
          (0...depth).each do |x|
            tile = block.call @tile, x, y, z
            if tile.nil?
              tile = MapTile.new(:blank, x, y, z, { passable: true }, @tileset)
            elsif tile.is_a?(Symbol) && !@tileset.nil? && @tileset.is_a?(MapTiles)
              if @tileset.metadata.has_key?(tile)
                tile = @tileset.metadata[tile].dup
                tile.x = x
                tile.y = y
                tile.z = z
              end
            end
            @tile[z][y][x] = tile
          end
        end
      end
    end

    def dirty(x, y, z = 0)
      self.data[z][y][x].dirty = true
    end

    def dirty_all_for(x, y)
      (0...depth).each do |z|
        self.data[z][y][x].dirty = true
      end
    end

    def dirty_all
      (0...depth).each do |z|
        (0...width).each do |x|
          (0...height).each do |y|
            self.data[z][y][x].dirty = true
          end
        end
      end
    end

    def clear(x, y, z = 0)
      self.data[z][y][x].dirty = false
    end

    def clear_all_for(x, y)
      (0...depth).each do |z|
        self.data[z][y][x].dirty = false
      end
    end

    def clear_all
      (0...depth).each do |z|
        (0...width).each do |x|
          (0...height).each do |y|
            self.data[z][y][x].dirty = false
          end
        end
      end
    end

    def dirty?(x, y, z = 0)
      self.data[z][y][x].dirty == true
    end

    def clear?(x, y, z = 0)
      self.data[z][y][x].dirty == false
    end

    def draw_tile(tile)
      use_tileset = tile.map_tiles || tileset

      use_tileset.draw(tile.sprite, tile.x, tile.y) if tile && use_tileset
    end

    def actor_can_move?(actor, direction)
      case direction
      when 'left'
        return false if (actor.x - 1).negative?

        tiles = elements_at(actor.x - 1, actor.y).filter do |tile|
          next unless tile

          tile.passable == false
        end
        return false if tiles.length.positive?
      when 'right'
        return false if (actor.x + 1) >= width

        tiles = elements_at(actor.x + 1, actor.y).filter do |tile|
          next unless tile

          tile.passable == false
        end
        return false if tiles.length.positive?
      when 'up'
        return false if (actor.y - 1).negative?

        tiles = elements_at(actor.x, actor.y - 1).filter do |tile|
          next unless tile

          tile.passable == false
        end
        return false if tiles.length.positive?
      when 'down'
        return false if (actor.y + 1) >= height

        tiles = elements_at(actor.x, actor.y + 1).filter do |tile|
          next unless tile

          tile.passable == false
        end
        return false if tiles.length.positive?
      end
      true
    end

    def elements_at(x, y, z = nil)
      elements = []

      (0...layers.length).each do |mz|
        (0...height).each do |my|
          (0...width).each do |mx|
            next unless x == mx && y == my
            next if z && z != mz

            symbol = @layers[mz][index_for(mx, my)]
            elements.append(tileset.metadata[symbol]) unless symbol.empty?
          end
        end
      end

      actors.each do |actor|
        elements.append(actor) if actor.x == x && actor.y == y
      end

      elements
    end

    def add_actor(actor)
      actor.map_tiles = @tileset unless actor.map_tiles
      actors.append(actor)
      dirty(actor.x, actor.y, actor.z)
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
      (0...depth).each do |z|
        dirty(tile.x, tile.y, z)
      end

      case direction
      when 'left'
        tile.x = tile.x - amount if tile.x - amount >= 0
      when 'right'
        tile.x = tile.x + amount if tile.x + amount < @width
      when 'up'
        tile.y = tile.y - amount if tile.y - amount >= 0
      when 'down'
        tile.y = tile.y + amount if tile.y + amount < @height
      else
        puts 'Unknown key'
      end
    end

    def draw
      return unless tileset

      (0...depth).each do |z|
        (0...width).each do |x|
          (0...height).each do |y|
            index = index_for(x, y)
            sprite = @layers[z][index]

            next if sprite.empty?

            if dirty?(x, y, z)
              tileset.draw(sprite, x, y)
              clear(x, y, z)
            end
          end
        end
      end

      @actors.each do |actor|
        actor.draw if dirty?(actor.x, actor.y, actor.z)
      end
    end

    def to_s
      "<Map tile_counts=#{width},#{height},#{depth} actors=#{@actors.length}>"
    end

    def inspect() = to_s
  end
end
