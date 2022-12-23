# frozen_string_literal: true

require 'ruby2d'

require_relative 'extensions'
require_relative 'map'
require_relative 'map_tiles'
require_relative 'map_tile'
require_relative 'actor'

$npc_tiles = MapTiles.new(
  'assets/tileset/enemies.png',
  tile_width: 32,
  tile_height: 32
)

$npc_tiles.set_sequential_metadata(
  %i[
    brigand                 rainbow_lich              rogue                   drow                    imp               salamander    horny_toad        gryphon               pirate            sword_orc
    sand_golem              dwarf                     axe_orc                 morning_star_orc        sword_goblin      scimitar_orc  staff_orc         gold_knight           staff_dwarf_mage  dwarf_mage
    ice_giant               fire_giant                minotaur                staff_dwarf_mage2       gelatinous_cube   dark_knight   water_elemental   giant_spider          demon             beholder
    brigand2                black_cloud               ochre_jelly             water_giant             giant_ant         drow2         fire_elemental    lightning_elemental   chimera           brigand2
    kobold                  kobold_mage               king                    fighter                 female_mage       orc_mage      stone_golem       ice_elemental         white_dragon      wolf
    great_dragon_head_left  great_dragon_head_right   great_dragon_body_left  great_dragon_body_right brown_minotaur    tan_drow      hooded_mage       staff_demon           phoenix           hydra
    vampire                 cleric                    dark_angel              dark_angel_magic        green_dragon      angel         red_staff_mage    skeleton              cyclops           purple_dragon
    lich                    red_beholder              blood_spider            female_lich             ochre_slime       yellow_slime  green_staff_mage  green_mage            undead_minotaur   green_jelly
    sea_dragon              tentacle_left             tentacle_right          dark_hooded_mage        dark_green_slime  green_slime   drow_thief        drow_ranger           female_mage_magic blood_splat
  ],
  passable: false
)

$map_tiles = MapTiles.new(
  'assets/tileset/bnk.png', # 64 tiles wide, 48 tiles tall
  tile_width: 32,
  tile_height: 32
)

$map_tiles.set_sequential_metadata(
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
    wet_marsh                       medium_gray                   medium_dark_gray                      dark_gray                           noise                     medium_noise                      dark_medium_noise               heavy_noise                 medium_heavy_noise
    dark_heavy_noise                green_noise                   medium_green_noise                    dark_green_noise                    tan_noise                 medium_tan_noise                  dark_tan_noise                  shallow_water               medium_shallow_water
    dark_shallow_water              deeper_water                  medium_deeper_water                   dark_deeper_water                   cold_marsh                medium_cold_marsh                 dark_cold_marsh                 swamp                       medium_swamp
    dark_swamp                      earth_cobble                  medium_earth_cobble                   dark_earth_cobble                   gray_cobble               medium_gray_cobble                dark_gray_cobble                yellow_lava_cobble          medium_yellow_lava_cobble
    dark_yellow_lava_cobble         red_lava_cobble               medium_red_lava_cobble                dark_red_lava_cobble                grassy_desert             medium_grassy_desert              dark_grassy_desert              rocky_desert                medium_rocky_desert
    dark_rocky_desert               irrigated_dry_earth           medium_irrigated_dry_earth            dark_irrigated_dry_earth            rough_snow                gray_rough_snow                   medium_rough_snow               dark_rough_snow             dark_rocky_snow
    wood_slat_floor                 grass_tree2                   medium_grass_tree2                    dark_grass_tree2                    grass_light_tree          medium_grass_light_tree           dark_grass_light_tree           grass_evergreen2            medium_grass_evergreen2
    dark_evergreen2                 dark_sand                     dark_sand_sw_water                    dark_sand_nw_water                  cactus                    medium_cactus                     dark_cactus                     palm                        medium_palm
    dark_palm                       choppy_water                  medium_choppy_water                   dark_choppy_water                   green_lava_cobble         medium_green_lava_cobble          dark_green_lava_cobble          deep_lava                   medium_deep_lava
    dark_deep_lava                  stony_mountain                medium_stony_mountain                 dark_stony_mountain                 snow                      medium_snow                       dark_snow                       snowy_mountain              medium_snowy_mountain
    dark_snowy_mountain             snowy_tree                    medium_snowy_tree                     dark_snowy_tree                     grassy_hills              medium_grassy_hills               dark_grassy_hills               snowy_hills                 medium_snowy_hills
    dark_snowy_hills                snowy_grass                   medium_snowy_grass                    dark_snowy_grass                    snowy_stone               medium_snowy_stone                dark_snowy_stone                cracked_snow                medium_cracked_snow
    dark_cracked_snow               cold_shallow_water            medium_cold_shallow_water             dark_cold_shallow_water             cold_deep_water           medium_cold_deep_water            dark_cold_deep_water            deep_lava2                  medium_deep_lava2
    dark_deep_lava2                 grassy_mountain               medium_grassy_mountain                dark_grassy_mountain                grassy_volcano            medium_grassy_volcano             dark_grassy_volcano             desert_mountain             medium_desert_mountain
    dark_desert_mountain            desert_volcano                medium_desert_volcano                 dark_desert_volcano                 rocky_desert_full_volcano medium_rocky_desert_full_volcano  dark_rocky_desert_full_volcano  grassy_desert_full_volcano  medium_grassy_desert_full_volcano
    dark_grassy_desert_full_volcano rocky_desert_volcano_eruption medium_rocky_desert_volcano_eruption  dark_rocky_desert_volcano_eruption  rocky_volcano_eruption    medium_rocky_volcano_eruption     dark_rocky_volcano_eruption     grassy_dead_tree            medium_grassy_dead_tree
    dark_grassy_dead_tree           desert_dead_tree              medium_desert_dead_tree               dark_desert_dead_tree               rocky_desert_dead_tree    medium_rocky_desert_dead_tree     dark_rocky_desert_dead_tree     sandy_desert_cactus         medium_sandy_desert_cactus
    dark_sandy_desert_cactus        seeded_crops                  medium_seeded_crops                   dark_seeded_crops                   young_crops               medium_young_crops                dark_young_crops                mature_crops                medium_mature_crops
    dark_mature_crops               harvested_crops               medium_harvested_crops                dark_harvested_crops                irrigated_crops           medium_irrigated_crops            dark_irrigated_crops            grassy_boulder              medium_grassy_boulder
    dark_grassy_boulder             wood_slat_floor_mast          wood_slat_floor_spinning_wheel        medium_cold_marsh_sinkhole          white_door_open           stars                             metal_plating                   mine_shaft_doorway          transparent
  ].map do |symbol|
    string = symbol.to_s
    result = symbol.to_sym
    %w[tree cactus boulder mountain closed volcano eruption water].each do |keyword|
      if string.include? keyword
        result = [symbol, false]
        break
      end
    end

    result
  end,
  passable: true,
  tileset: $map_tiles
)
