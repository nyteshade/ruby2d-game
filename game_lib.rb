require 'ruby2d' unless defined?(Ruby2D)
require 'csv' unless defined?(CSV)
require 'json' unless defined?(JSON)
require 'pathname' unless defined?(Pathname)

module Game
  TiledProperty = Struct.new(:name, :type, :value)

  class Tiles < Ruby2D::Tileset
    attr_accessor(
      :tile_width, :tile_height, :tile_definitions,
      :path, :tiles, :metadata
    )

    def initialize(...)
      super

      self.metadata = {
        tiles: Array.new(height) { Array.new(width) },
        order: [ ],
        symbols: { }
      }
    end

    def [](x_or_symbol, y = nil, type = :tile)
      x = nil
      x = x_or_symbol unless x_or_symbol.is_a? Symbol

      if x.is_a? Integer and y.nil?
        return metadata[:order][x]
      end

      if x_or_symbol.is_a? Symbol
        metadata[:symbols][x_or_symbol]
      else
        return nil unless metadata[:tiles][y][x]

        case type
        when :tile then metadata[:tiles][y][x]
        when :symbol then metadata[:tiles][y][x].name
        when :order then metadata[:order][x]
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
      metadata[:order].append(tile)
    end

    def define_tile(name, x, y, rotate: nil, flip: nil)
      super

      tile = Tile[name.to_sym, Point[x,y]]
      metadata[:tiles][y][x] = tile
      metadata[:symbols][tile.name] = tile
      metadata[:order].append(tile)
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

    def image_width = @width
    def image_height = @height
    def width = @width / tile_width
    def height = @height / tile_height

    def inspect
      "<Tiles w=#{width} h=#{height} defined=#{metadata[:symbols].size}>"
    end

    def self.from_tsj(path_to_tsj_file)
      path_to_tsj_file = $tiled_path.join(Pathname.basename(path_to_tsj_file))
      return nil unless path_to_tsj_file.exist?

      json = JSON::parse(File::read(path_to_tsj_file), {object_class: OpenStruct})
      return nil unless json

      tile_size = OpenStruct.new({
        height: json.tileheight,
        width: json.tilewidth
      })

      image = $image_path.join(Pathname.basename(json.image))
      return nil unless image.exist?

      tiles = Tiles.new(
        image,
        tile_width: tile_size.width,
        tile_height: tile_size.height
      )
      return nil unless tiles

      json.tiles.each do |tile|
        props = {}

        tile.properties.each do |property|
          case property.type
          when "float" then props[property.name.to_sym] = property.value.to_f
          when "int" then props[property.name.to_sym] = property.value.to_i
          when "file" then props[property.name.to_sym] = property.value.to_s
          when "bool" then props[property.name.to_sym] = true?(property.value)
          when "color" then props[property.name.to_sym] = {
            a: property.value[1...3],
            r: property.value[3...5],
            g: property.value[5...7],
            b: property.value[7...9]
          }
          else props[property.name.to_sym] = property.value
          end
        end

        width = json.imagewidth / json.tilewidth
        x = tile.id % width
        y = tile.id / width

        tiles[x, y] = Tile[props[:name].to_sym, Point[x, y], props[:passable], props, tiles]
      end

      tiles
    end
  end

  Size = Struct.new(:width, :height) do
    def initialize(width = 0, height = 0)
      super
    end

    def w = self.width
    def h = self.height
    def w=(value); self.width = value; end
    def h=(value); self.height = value; end

    def coordinates = [w, h]
  end

  Point = Struct.new(:x, :y, :z) do
    def initialize(x = 0, y = 0, z = 0)
      super
    end

    def coordinates
      [x, y, z]
    end

    def to_s = "<Game::Point x=#{x} y=#{y} z=#{z}>"
  end

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

    def to_s = "<Rect position=#{position.coordinates} size=#{size.coordinates} t,r,b,l=#{edges}>"
  end

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

    def inspect() = to_s
  end

  class Player < Actor
    def initialize(name, position, passable = false, props = { }, tileset = nil)
      super
    end

    def player? = true

    def to_s = super.to_s.gsub("Actor", "Player")
  end

  Map = Struct.new(:width, :height, :depth, :tileset, :actors, :data) do
    attr_accessor :visible, :first_gid

    def initialize(width, height, depth = 1, tileset = nil, actors = [], all_of_type: nil)
      self.actors = actors || []
      self.data = Array.new(depth) { Array.new(height) { Array.new(width) } }
      self.tileset = tileset
      self.tileset = nil unless tileset&.is_a? Game::Tiles

      set_default_tile = tileset && all_of_type && all_of_type.is_a?(Symbol)

      self.width = width
      self.height = height
      self.depth = depth
      self.visible = Rect[Size[width, height], Point[]]

      default_tile = nil
      if set_default_tile && self.tileset[all_of_type]
        default_tile = self.tileset[all_of_type]
      end

      each_tile_of(self.data, :meta) do |point, _|
        next { tile: default_tile, dirty: false }
      end
    end

    def wrap_bounds(x, y, z)
      max_point = Point[
        self.data[0][0].size,
        self.data[0].size,
        self.data.size
      ]

      x = 0 if x < -(max_point.x) or x >= max_point.x
      y = 0 if y < -(max_point.y) or y >= max_point.y
      z = 0 if z < -(max_point.z) or z >= max_point.z

      return [x, y, z]
    end

    def [](x, y, z = 0, type = :tile)
      if x.is_a? Game::Point
        x, y, z = x.coordinates
      end

      x, y, z = wrap_bounds x, y, z

      resource = self.data[z][y][x]

      case type
      when :tile then resource[:tile]
      when :dirty then resource[:dirty]
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

    def each_tile_of(multi_dim_array, result_type = :tile, offset = Point[], by = nil, only_z: nil, &block)
      return unless block_given?
      multi_dim_array = self.data unless multi_dim_array

      use_depth = multi_dim_array.size
      use_height = by&.y || ((multi_dim_array[0].size) + offset.y)
      use_width = by&.x || ((multi_dim_array[0][0].size) + offset.x)

      start_depth = only_z || 0
      end_depth = (only_z && (only_z + 1)) || use_depth

      (start_depth...end_depth).each do |z|
        (offset.y...use_height).each do |y|
          (offset.x...use_width).each do |x|
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
        x, y, z = wrap_bounds x, y, z
        self.data[z][y][x][:dirty] = true
      end
    end

    def dirty_all_for(x, y)
      (0...depth).each do |z|
        x, y, z = wrap_bounds x, y, z
        self.data[z][y][x][:dirty] = true
      end
    end

    def dirty_all
      (0...depth).each do |z|
        (0...width).each do |x|
          (0...height).each do |y|
            x, y, z = wrap_bounds x, y, z
            self.data[z][y][x][:dirty] = true
          end
        end
      end
    end

    def clear(x, y, z = nil)
      if z.nil?
        clear_all_for x, y
      else
        x, y, z = wrap_bounds x, y, z
        self.data[z][y][x][:dirty] = false
      end
    end

    def clear_all_for(x, y)
      (0...depth).each do |z|
        x, y, z = wrap_bounds x, y, z
        self.data[z][y][x][:dirty] = false
      end
    end

    def clear_all
      (0...depth).each do |z|
        (0...width).each do |x|
          (0...height).each do |y|
            x, y, z = wrap_bounds x, y, z
            self.data[z][y][x][:dirty] = false
          end
        end
      end
    end

    def dirty?(x, y, z = 0)
      x, y, z = wrap_bounds x, y, z
      self.data[z][y][x][:dirty] == true
    end

    def clear?(x, y, z = 0)
      x, y, z = wrap_bounds x, y, z
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

          next tile.passable == false
        end
        return false if tiles.length.positive?
      when 'right'
        return false if (actor.x + 1) >= width

        tiles = elements_at(actor.x + 1, actor.y).filter do |tile|
          not_array = !tile.is_a?(Array)
          not_nil = !tile.nil?

          next unless [not_array, not_nil].all?

          next tile.passable == false
        end
        return false if tiles.length.positive?
      when 'up'
        return false if (actor.y - 1).negative?

        tiles = elements_at(actor.x, actor.y - 1).filter do |tile|
          not_array = !tile.is_a?(Array)
          not_nil = !tile.nil?

          next unless [not_array, not_nil].all?

          next tile.passable == false
        end
        return false if tiles.length.positive?
      when 'down'
        return false if (actor.y + 1) >= height

        tiles = elements_at(actor.x, actor.y + 1).filter do |tile|
          not_array = !tile.is_a?(Array)
          not_nil = !tile.nil?

          next unless [not_array, not_nil].all?

          next tile.passable == false
        end
        return false if tiles.length.positive?
      end
      return true
    end

    def elements_at(x, y = 0, z = nil, filter = nil, &block)
      if x.is_a? Tile::Point
        x, y, z = x.coordinates
      end

      elements = Array.new(depth)

      each_tile_of(data) do |position, _|
        dx, dy, dz = position.coordinates

        x_matches = x == dx
        y_matches = y == dy
        z_matches = z ? z == dz : true
        not_nil = !self[dx, dy, dz].nil?
        conditions = [x_matches, y_matches, z_matches, not_nil]

        if conditions.all?
          elements[dz] = self[dx, dy, dz]
        end
      end

      actors.each do |actor|
        not_nil = !actor.nil?
        not_array = !actor.is_a?(Array)

        next unless [not_nil, not_array].all?

        elements[actor.z] = actor if actor.x == x && actor.y == y
      end

      if !filter.nil? and filter.is_a?(Proc)
        elements = elements.filter &filter
      end

      if block_given?
        elements.each &block
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
        return true
      elsif y < 0 || y >= height
        return true
      elsif z < 0 || z >= depth
        return true
      else
        return false
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

            unless element.nil?
              element = element.reduce(nil) do |_, c|
                if c.respond_to?(:z) && z == nz
                  next c
                end
                next nil
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
        if tile.x - amount >= 0
          tile.x = tile.x - amount
          if tile.is_a? Player
            visible.translate(-1, 0)
          end
        end
      when 'right'
        if tile.x + amount < width
          tile.x = tile.x + amount
          if tile.is_a? Player
            visible.translate(1, 0)
          end
        end
      when 'up'
        if tile.y - amount >= 0
          tile.y = tile.y - amount
          if tile.is_a? Player
            visible.translate(0, -1)
          end
        end
      when 'down'
        if tile.y + amount < height
          tile.y = tile.y + amount
          if tile.is_a? Player
            visible.translate(0, 1)
          end
        end
      else
        puts 'Unknown key'
      end

      result = (tile.position == old) ? false : true
      if result
        dirty_all
      end

      return result
    end

    def draw
      return false unless self.tileset

      depth.times do |z|
        (visible.top...visible.bottom).each do |y|
          (visible.left...visible.right).each do |x|
            tile = self[x, y, z]

            next unless tile&.is_a?(Tile) or !tile.nil?

            tileset.draw tile.name, Point[x - visible.x,y - visible.y,z] if dirty?(x, y, z)
            clear x, y, z if dirty? x, y, z
          end
        end
      end

      actors.filter { |a| a.player? }.each do |player|
        draw_at = Point[visible.width / 2, visible.height / 2, 1]
        player.draw draw_at
      end

      actors.filter { |a| !a.player? }.each do |actor|
        draw_at = Point[actor.x - visible.x, actor.y - visible.y, 1]
        actor.draw draw_at
      end

      return true
    end

    def to_s
      "<Map tile_counts=#{width},#{height},#{depth} actors=#{@actors&.length}>"
    end

    def self.search_adjacent(map, position, gid)
      tiles = []

      map.depth.times do |z|
        ((position.y-1)...(position.y+1)).each do |y|
          next if y < 0 || y >= map.height
          ((position.x-1)...(position.x+1)).each do |x|
            next if x < 0 || x >= map.width
            tiles.append(map[x, y, z])
          end
        end
      end

      tiles.filter { |e| e && e.props.has_key?(:gid) && e.props[:gid] == gid }.first
    end

    def self.from_tmj(path_to_tmj_file)
      path_to_tmj_file = $tiled_path.join(Pathname.new(path_to_tmj_file).basename)
      return nil unless path_to_tmj_file.exist?

      json = JSON::parse(File.read(path_to_tmj_file), {object_class: OpenStruct})
      return nil unless json

      source = json.dig(:tilesets, 0, :source)
      source = $tiled_path.join(Pathname.new(source).basename)
      return nil unless source.exist?

      offset = json.dig(:tilesets, 0, :firstgid)
      offset = 0 unless offset.is_a? Integer

      tile_size = OpenStruct.new({
        width: json.tilewidth,
        height: json.tileheight
      })

      map_size = OpenStruct.new({
        width: json.width,
        height: json.height
      })

      tiles = Tiles.from_tsj(source)
      return nil unless tiles

      layers = json.dig("layers")
      return nil unless layers

      layers = layers.filter do |layer| layer.type == "tilelayer"; end
      result = Map.new(map_size.width, map_size.height, json.dig("layers").size || 1, tiles)
      result.first_gid = offset
      layers.each_with_index do |layer, z|
        data = layer.data
        map_size.height.times do |y|
          map_size.width.times do |x|
            index = (y * map_size.width) + x
            next if (data[index] == 0) and (result.first_gid == 1)

            tile_idx = [0, data[index] - offset].max
            tile = tiles[tile_idx].dup
            tile.tileset = tiles
            tile.position = Point[x, y, z]
            tile.props[:gid] = tile_idx
            result[x, y, z] = tile
          end
        end
      end

      objects = json.dig("layers").first_of { |l| l.type == "objectgroup" }
      objects = objects.objects unless objects.nil?

      if objects
        objects.each do |object|
          x = object.x.ceil.to_i / tile_size.width
          y = object.y.ceil.to_i / tile_size.height
          og_tile = tiles[object.gid - offset]
          map_tile = Map.search_adjacent(result, Point[x,y], object.gid - offset)

          next if map_tile.nil?

          result[map_tile.position.x, map_tile.position.y, result.depth - 1] = og_tile.dup

          if object.properties.is_a? Array
            object.properties.each do |property|
              map_tile.props[property.name.to_sym] = property.value
            end
          end
        end
      end

      return result
    end
  end
end
