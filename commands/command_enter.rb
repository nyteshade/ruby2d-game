module Game
  def command_enter(event, map, player)
    tiles = map.elements_at(player.x, player.y)
    tiles.each do |tile|
      next unless tile.is_a? Game::Tile

      conditions = [
        tile.props.has_key?(:enterable),
        tile.props.has_key?(:destination_map),
        tile.props.has_key?(:destination_x),
        tile.props.has_key?(:destination_y),
        tile.props.has_key?(:destination_z)
      ]
      if conditions.all? and tile.props[:enterable]
        dmap = tile.props[:destination_map]
        puts dmap
        next unless dmap.size > 0

        dpos = Point[
          tile.props[:destination_x],
          tile.props[:destination_y],
          tile.props[:destination_z]
        ]

        next unless dmap.end_with?(".tmj")

        dmap = Map.from_tmj(dmap, map.tileset)
        dmap.visible.translate (dmap.width/2-dmap.width/4), (dmap.height/2-dmap.height/4)

        if dmap
          dest_elements = dmap.elements_at(dpos)
          passable = true
          dest_elements.each do |element|
            if element and !element.passable
              passable = false
              break
            end
          end

          #TODO Remove this
          passable = true
          if passable
            i = map.actors.size - 1
            until i.negative?
              map.remove_actor map.actors[0]
              i = i - 1
            end

            $player = Player[:avatar, dpos, false, {}, dmap.tileset]
            $map = dmap
            #Ruby2D::Window::clear
            $map.add_actor player
            $map.draw

            puts "Map #{$map.object_id} DMap #{dmap.object_id} map #{map.object_id}"
            puts "Map.tileset #{$map.tileset.object_id} map #{map.tileset.object_id}"
            $map.each_tile_of do |point, _|
              x, y, z = point.coordinates
              tile = $map[x, y, z]
              next unless tile

              puts "tile: #{tile.name} (#{point.coordinates}) tileset: #{tile.tileset.object_id}"
              next nil
            end
          end
        end
      end
    end
  end
end
