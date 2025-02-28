require 'ruby2d/core' unless defined?(Ruby2D)
require 'json' unless defined?(JSON)
require 'pathname' unless defined?(Pathname)

require_relative 'game_size' unless defined? Game::Size
require_relative 'game_point' unless defined? Game::Point
require_relative 'game_rect' unless defined? Game::Rect
require_relative 'game_tiled_property' unless defined? Game::TiledProperty
require_relative 'game_tiles' unless defined? Game::Tiles
require_relative 'game_map' unless defined? Game::Map

require_relative 'commands/command_enter' unless Game::method_defined? :command_enter
require_relative 'commands/command_open' unless Game::method_defined? :command_open
