require 'ruby2d/core' unless defined? Ruby2D
require_relative 'game_actor' unless defined? Game::Actor

module Game
  class Player < Actor
    include Ruby2D::Renderable

    def initialize(name, position, passable = false, props = { }, tileset = nil)
      super
    end

    def player? = true

    def to_s = super.to_s.gsub("Actor", "Player")
  end
end
