require 'ruby2d/core' unless defined? Ruby2D
require 'json' unless defined? JSON
require 'pathname' unless defined? Pathname

require_relative 'game_point' unless defined? Game::Point
require_relative 'game_tile' unless defined? Game::Tile

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
        order: [],
        symbols: {}
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

      tile = Tile[name.to_sym, Point[x, y]]
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

      json = JSON::parse(File::read(path_to_tsj_file), { object_class: OpenStruct })
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
        tile_height: tile_size.height,
        scale: $use_scale
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
end
