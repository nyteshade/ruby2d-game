module Game
  TileHeldOpen = Struct.new(:by, :tile_opened, :tile_under, :max_ticks, :cur_ticks) do
    def is_opened?
      !is_closed?
    end

    def is_closed?
      tile_opened.nil? || !(tile_opened.is_a? Tile)
    end

    def initialize(tile_opened = nil, by = $player, max_ticks = 15, tile_under = nil)
      super

      if tile_opened.is_a? Tile
        cur_ticks = @total_ticks
      end
    end

    def open(tile_opened, by = $player, max_ticks = 15)
      if tile_opened.is_a? Tile
        puts "Tile #{tile_opened} opened"
        cur_ticks = @total_ticks
      else
        puts "Unable to open #{tile_opened}"
        tile_opened = nil
        tile_under = nil
        cur_ticks = nil
      end
    end

    def close
      puts "Closed Tile #{tile_opened}"
      tile_opened = nil
      tile_under = nil
      cur_ticks = nil
    end
  end

  def command_open(event, map, player, direction)

  end
end