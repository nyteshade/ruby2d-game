require 'ruby2d/core' unless defined?(Ruby2D)
require 'json' unless defined?(JSON)
require 'pathname' unless defined?(Pathname)

require_relative 'game_point' unless defined? Game::Point
require_relative 'game_size' unless defined? Game::Size
require_relative 'game_rect' unless defined? Game::Rect
require_relative 'game_tile' unless defined? Game::Tile
require_relative 'game_player' unless defined? Game::Player
require_relative 'game_tiles' unless defined? Game::Tiles

module Game
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

    def each_tile_of(multi_dim_array = nil, result_type = :tile, offset = Point[], by = nil, only_z: nil, &block)
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

    def elements_at(x, y = 0, z = nil, filter = nil, compact = true, &block)
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

      if compact
        elements.compact!
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
          if tile.player?
            visible.translate(-1, 0)
          end
        end
      when 'right'
        if tile.x + amount < width
          tile.x = tile.x + amount
          if tile.player?
            visible.translate(1, 0)
          end
        end
      when 'up'
        if tile.y - amount >= 0
          tile.y = tile.y - amount
          if tile.player?
            visible.translate(0, -1)
          end
        end
      when 'down'
        if tile.y + amount < height
          tile.y = tile.y + amount
          if tile.player?
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

    def self.from_tmj(path_to_tmj_file, use_tileset = nil)
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

      tiles = use_tileset || Tiles.from_tsj(source)
      return nil unless tiles
      return nil unless tiles.is_a? Game::Tiles

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
            next if data[index] < result.first_gid # skipping unhandled tiles

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
