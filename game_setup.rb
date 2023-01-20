# frozen_string_literal: true

require 'ruby2d'

require_relative 'game_lib'
require_relative 'wrandom'

include Game
include WeightedRandom

$use_biome = if ENV.has_key?("biome") then ENV["biome"].to_sym else :snow end
$use_level = if ENV.has_key?("level") then ENV["level"].to_sym else :light end
$use_scale = if ENV.has_key?("scale") then ENV["scale"].to_f else 1.0 end

$map_tiles = Tiles.new(
  'assets/tileset/combined.png', # 64 tiles wide, 48 tiles tall
  tile_width: 32,
  tile_height: 32,
  scale: (defined?($use_scale)) ? $use_scale : 1
)

$map_tiles.set_sequential_definitions(
  %i[
    black                           light_gray                    medium_gray                           dark_gray                           light_bricks              medium_bricks                     dark_bricks                     packed_earth                medium_packed_earth
    dark_packed_earth               light_lava_cracked_earth      medium_lava_cracked_earth             dark_lava_cracked_earth             light_marsh               medium_marsh                      dark_marsh                      light_marsh_lava            medium_marsh_lava
    dark_marsh_lava                 closed_skull_gate             open_skull_gate                       broken_skull_gate                   provisions_door           armory_door                       weaponry_door                   clergy_door                 alchemy_door
    jewlry_door                     death_door                    closed_door                           library_door                        dry_earth                 medium_dry_earth                  dark_dry_earth                  cobblestone                 medium_coblestone
    dark_cobblestone                clear_tree                    clear_medium_tree                     clear_dark_tree                     grass_tree                medium_grass_tree                 dark_grass_tree                 grass_evergreen             medium_grass_evergreen
    dark_grass_evergreen            keep                          castle                                town                                shallow_water             medium_shallow_water              dark_shallow_water              deep_water                  medium_deep_water
    dark_deep_water                 red_lava                      medium_red_lava                       dark_red_lava                       orange_lava               medium_orange_lava                dark_orange_lava                white_bricks                medium_white_bricks
    dark_white_bricks               dark_closed_door              dark_open_door                        dark_broken_door                    fencing_door              monster_door                      pub_door                        archery_door                armory2_door
    strength_door                   rogue_door                    tower_door                            clergy2_door                        dark_tower_door           sword_and_cross_door              bank_door                       forest_door                 inn_door
    library2_door                   astronomy_door                kingly_door                           stairs_up                           stairs_down               dark_rough_wall                   light_rough_wall                mountain                    smooth_stone
    dark_smooth_stone               rough_stone                   medium_rough_stone                    dark_rough_stone                    brick_wall                medium_brick_wall                 dark_brick_wall                 wood_closed_door            wood_open_door
    wood_broken_door                stone_closed_door             stone_open_door                       stone_broken_door                   cobble_closed_skull_gate  cobble_open_skull_gate            cobble_broken_skull_gate        cobble_closed_door          cobble_open_door
    cobble_broken_door              cobble_closed_wood_door       cobble_open_wood_door                 cobble_broken_wood_door             cobble_closed_stone_door  cobble_open_stone_door            cobble_broken_stone_door        cobble_stairs_up            cobble_stairs_down
    wet_marsh                       fine_stone                    medium_fine_stone                     dark_fine_stone                     stone                     medium_stone                      dark_medium_stone               rough_stone                 medium_rough_stone
    dark_rough_stone                grass                         medium_grass                          dark_grass                          sand                      medium_sand                       dark_sand                       shallow_water               medium_shallow_water
    dark_shallow_water              deeper_water                  medium_deeper_water                   dark_deeper_water                   cold_marsh                medium_cold_marsh                 dark_cold_marsh                 swamp                       medium_swamp
    dark_swamp                      earth_cobble                  medium_earth_cobble                   dark_earth_cobble                   gray_cobble               medium_gray_cobble                dark_gray_cobble                yellow_lava_cobble          medium_yellow_lava_cobble
    dark_yellow_lava_cobble         red_lava_cobble               medium_red_lava_cobble                dark_red_lava_cobble                grass_desert              medium_grass_desert               dark_grass_desert               rocky_desert                medium_rocky_desert
    dark_rocky_desert               irrigated_dry_earth           medium_irrigated_dry_earth            dark_irrigated_dry_earth            rough_snow                gray_rough_snow                   medium_rough_snow               dark_rough_snow             dark_rocky_snow
    wood_slat_floor                 grass_tree2                   medium_grass_tree2                    dark_grass_tree2                    grass_light_tree          medium_grass_light_tree           dark_grass_light_tree           grass_evergreen2            medium_grass_evergreen2
    dark_evergreen2                 dark_sand                     dark_sand_sw_water                    dark_sand_nw_water                  cactus                    medium_cactus                     dark_cactus                     palm                        medium_palm
    dark_palm                       choppy_water                  medium_choppy_water                   dark_choppy_water                   green_lava_cobble         medium_green_lava_cobble          dark_green_lava_cobble          deep_lava                   medium_deep_lava
    dark_deep_lava                  stony_mountain                medium_stony_mountain                 dark_stony_mountain                 snow                      medium_snow                       dark_snow                       snowy_mountain              medium_snowy_mountain
    dark_snowy_mountain             snowy_tree                    medium_snowy_tree                     dark_snowy_tree                     grass_hills               medium_grass_hills                dark_grass_hills                snowy_hills                 medium_snowy_hills
    dark_snowy_hills                snowy_grass                   medium_snowy_grass                    dark_snowy_grass                    snowy_stone               medium_snowy_stone                dark_snowy_stone                cracked_snow                medium_cracked_snow
    dark_cracked_snow               cold_shallow_water            medium_cold_shallow_water             dark_cold_shallow_water             cold_deep_water           medium_cold_deep_water            dark_cold_deep_water            deep_lava2                  medium_deep_lava2
    dark_deep_lava2                 grass_mountain                medium_grass_mountain                 dark_grass_mountain                 grass_volcano             medium_grass_volcano              dark_grass_volcano              desert_mountain             medium_desert_mountain
    dark_desert_mountain            desert_volcano                medium_desert_volcano                 dark_desert_volcano                 rocky_desert_full_volcano medium_rocky_desert_full_volcano  dark_rocky_desert_full_volcano  grass_desert_full_volcano   medium_grass_desert_full_volcano
    dark_grass_desert_full_volcano  rocky_desert_volcano_eruption medium_rocky_desert_volcano_eruption  dark_rocky_desert_volcano_eruption  rocky_volcano_eruption    medium_rocky_volcano_eruption     dark_rocky_volcano_eruption     grass_dead_tree             medium_grass_dead_tree
    dark_grass_dead_tree            desert_dead_tree              medium_desert_dead_tree               dark_desert_dead_tree               rocky_desert_dead_tree    medium_rocky_desert_dead_tree     dark_rocky_desert_dead_tree     sand_desert_cactus          medium_sand_desert_cactus
    dark_sand_desert_cactus         seeded_crops                  medium_seeded_crops                   dark_seeded_crops                   young_crops               medium_young_crops                dark_young_crops                mature_crops                medium_mature_crops
    dark_mature_crops               harvested_crops               medium_harvested_crops                dark_harvested_crops                irrigated_crops           medium_irrigated_crops            dark_irrigated_crops            grass_boulder               medium_grass_boulder
    dark_grass_boulder              wood_slat_floor_mast          wood_slat_floor_spinning_wheel        medium_cold_marsh_sinkhole          white_door_open           stars                             metal_plating                   mine_shaft_doorway          transparent
    brigand                         rainbow_lich                  rogue                                 drow                                imp                       salamander                        horny_toad                      gryphon                     pirate
    sword_orc                       earth_golem                   dwarf                                 axe_orc                             morning_star_orc          sword_goblin                      scimitar_orc                    staff_orc                   gold_knight
    staff_dwarf_mage                dwarf_mage                    ice_giant                             fire_giant                          minotaur                  staff_dwarf_mage2                 gelatinous_cube                 dark_knight                 water_elemental
    giant_spider                    demon                         beholder                              brigand2                            black_cloud               ochre_jelly                       water_giant                     giant_ant                   drow2
    fire_elemental                  lightning_elemental           chimera                               brigand3                            kobold                    kobold_mage                       king                            fighter                     female_mage
    orc_mage                        stone_golem                   ice_elemental                         white_dragon                        wolf                      great_dragon_head_left            great_dragon_head_right         great_dragon_body_left      great_dragon_body_right
    brown_minotaur                  tan_drow                      hooded_mage                           staff_demon                         phoenix                   hydra                             vampire                         cleric                      dark_angel
    dark_angel_magic                green_dragon                  angel                                 red_staff_mage                      skeleton                  cyclops                           purple_dragon                   lich                        red_beholder
    blood_spider                    female_lich                   ochre_slime                           yellow_slime                        green_staff_mage          green_mage                        undead_minotaur                 green_jelly                 sea_dragon
    tentacle_left                   tentacle_right                dark_hooded_mage                      dark_green_slime                    green_slime               drow_thief                        drow_ranger                     female_mage_magic           blood_splat
  ].map do |symbol|
    string = symbol.to_s
    result = symbol.to_sym
    %w[tree cactus boulder mountain closed volcano eruption water evergreen].each do |keyword|
      if string.include? keyword
        result = [symbol, false]
        break
      end
    end

    result
  end,
  passable: true
)

puts $map_tiles

def prefix(key, biome = '', level = :light)
  prefix = ''

  biome = biome || ''
  level = level || :light

  prefix = "#{prefix}#{level}_" unless level == :light
  prefix = "#{prefix}#{biome}_" unless biome.empty?

  "#{prefix}#{key}".to_s
end

def get_chart(key, biome = :grass, level = :light)
  key_prefix = prefix(key, biome, level)
  $charts ||= {}

  if $charts.include?(key_prefix)
    $charts[key_prefix]
  else
    puts key_prefix
    nil
  end
end

def get_biome
  :grass unless defined? $use_biome
end

def get_level
  :light unless defined? $use_level
end

def tile_position
  $temp_tile_position ||= Point[0, 0, 0]
end

def set_tile_position(x = 0, y = 0, z = 0)
  if x.is_a? Point
    $temp_tile_position = x
  else
    $temp_tile_position = Point[x, y, z]
  end
end

$charts = {
  mountains: WRandom.new([
    WRItem[lambda { get_chart(:hills, nil) }, 2.0],
    WRItem[lambda { get_chart(:water, nil) }],
    WRItem[lambda { get_chart(:settlement, nil) }],
    WRItem[lambda { prefix(:mountain, get_biome, get_level) }, 3.0],
    WRItem[lambda { prefix(:boulder, :grass, get_level) }],
    WRItem[lambda { prefix(:volcano, get_biome, get_level) }],
    WRItem[lambda { prefix(:volcano_eruption, get_biome, get_level) }]
  ]),

  hills: WRandom.new([
     WRItem[lambda { prefix(:hill, get_biome, get_level) }, 3.0],
     WRItem[lambda { get_chart(:trees, get_biome, get_level) }],
     WRItem[lambda { get_chart(:water, get_biome, get_level) }],
     WRItem[lambda { get_chart(:rocky_terrain, get_biome, get_level) }, 2.0],
     WRItem[lambda { get_chart(:mountains, get_biome, get_level) }],
     WRItem[lambda { get_chart(:settlements, get_biome, get_level) }],
     WRItem[lambda { prefix(:boulder, :grass, get_level) }],
  ]),

  settlements: WRandom.new([
     WRItem[lambda { prefix(:keep, nil, nil) }, 2.0],
     WRItem[lambda { prefix(:castle, nil, nil) }],
     WRItem[lambda { prefix(:town, nil, nil) }, 7.0]
  ]),
}

$biomes = {
  snow: {
    light: { passable: [], trees: [], mountains: [] },
    medium: { passable: [], trees: [], mountains: [] },
    dark: { passable: [], trees: [], mountains: [] }
  },
  stone: {
    light: { passable: [], trees: [], mountains: [] },
    medium: { passable: [], trees: [], mountains: [] },
    dark: { passable: [], trees: [], mountains: [] }
  },
  grass: {
    light: { passable: [], trees: [], mountains: [] },
    medium: { passable: [], trees: [], mountains: [] },
    dark: { passable: [], trees: [], mountains: [] }
  },
  sand: {
    light: { passable: [], trees: [], mountains: [] },
    medium: { passable: [], trees: [], mountains: [] },
    dark: { passable: [], trees: [], mountains: [] }
  }
}

def check_for_and_store_in(biome, key)
  string = key.to_s
  level = :light
  level = :dark if string.include? 'dark'
  level = :medium if string.include? 'medium'

  if (string.include? 'tree') || (string.include? 'evergreen')  || (string.include? 'cactus')
    $biomes[biome][level][:trees].push(key)
  elsif (string.include? 'mountain') || (string.include? 'volcano') || (string.include? 'boulder')
    $biomes[biome][level][:mountains].push(key)
  else
    $biomes[biome][level][:passable].push(key)
  end
end

$map_tiles.metadata[:symbols].filter do |key|
  string = key
  string = key.to_s if key.is_a?(Symbol)

  if string.include? 'snow'
    check_for_and_store_in(:snow, key)
  elsif string.include? 'grass'
    check_for_and_store_in(:grass, key)
  elsif (string.include? 'sand') || (string.include? 'desert')
    check_for_and_store_in(:sand, key)
  end
end

%i[
  brigand                         rainbow_lich                  rogue                                 drow                                imp                       salamander                        horny_toad                      gryphon                     pirate
  sword_orc                       earth_golem                   dwarf                                 axe_orc                             morning_star_orc          sword_goblin                      scimitar_orc                    staff_orc                   gold_knight
  staff_dwarf_mage                dwarf_mage                    ice_giant                             fire_giant                          minotaur                  staff_dwarf_mage2                 gelatinous_cube                 dark_knight                 water_elemental
  giant_spider                    demon                         beholder                              brigand2                            black_cloud               ochre_jelly                       water_giant                     giant_ant                   drow2
  fire_elemental                  lightning_elemental           chimera                               brigand3                            kobold                    kobold_mage                       king                            fighter                     female_mage
  orc_mage                        stone_golem                   ice_elemental                         white_dragon                        wolf                      great_dragon_head_left            great_dragon_head_right         great_dragon_body_left      great_dragon_body_right
  brown_minotaur                  tan_drow                      hooded_mage                           staff_demon                         phoenix                   hydra                             vampire                         cleric                      dark_angel
  dark_angel_magic                green_dragon                  angel                                 red_staff_mage                      skeleton                  cyclops                           purple_dragon                   lich                        red_beholder
  blood_spider                    female_lich                   ochre_slime                           yellow_slime                        green_staff_mage          green_mage                        undead_minotaur                 green_jelly                 sea_dragon
  tentacle_left                   tentacle_right                dark_hooded_mage                      dark_green_slime                    green_slime               drow_thief                        drow_ranger                     female_mage_magic           blood_splat
].each do |symbol|
  $map_tiles.metadata[:symbols][symbol].passable = false
end

$map = Map.new(20, 15, 2, $map_tiles)
$map.each_tile_of($map.data, only_z: 0) do |position, _|
  x, y, z = position.coordinates
  symbol = $biomes[$use_biome][$use_level][:passable].choose_one
  obstacle = nil

  if rand(0...100) < 15
    obstacle = $biomes[$use_biome][$use_level][:trees].choose_one
  elsif rand(0...100) < 5
    obstacle = $biomes[$use_biome][$use_level][:mountains].choose_one
  end

  tile = $map_tiles[symbol]
  $map[x, y, z] = tile
  unless obstacle.nil?
    $map[x, y, z + 1] = $map_tiles[obstacle]
  end
  next nil
end

$map.relative_grid 0,0
