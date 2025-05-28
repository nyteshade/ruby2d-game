require 'ruby2d/core' unless defined? Ruby2D
require_relative 'game_point' unless defined? Game::Point

module Game
  Tile = Struct.new(:name, :position, :passable, :props, :tileset) do
    include Ruby2D::Renderable

    attr_accessor :animation_time, :current_frame

    def x = position.x
    def y = position.y
    def z = position.z

    def x=(value); position.x = value; end
    def y=(value); position.y = value; end
    def z=(value); position.z = value; end

    def initialize(name, position = Point.new, passable = true, props = { }, tileset = nil)
      super
      @animation_time = 0.0
      @current_frame = name
    end

    def allows_passage?
      # First check if props exists and has a passable property defined
      if props && !props[:passable].nil?
        # If props.passable is defined (true or false), use that value
        return props[:passable]
      end

      # Otherwise, fall back to the tile's default passable value
      # If passable is nil, return false as specified
      return passable == true
    end

    def animated?
      # Check for animation properties - either explicitly enabled or has animation chain
      return false unless props
      
      # Explicitly animated
      return true if props[:animated] == true
      
      # Has animation chain (duration and next frame)
      has_duration = props[:animated_duration] && props[:animated_duration] > 0
      has_next = props[:animated_next] && !props[:animated_next].empty?
      
      has_duration && has_next
    end

    def update_animation(delta_time)
      return unless animated? && props[:animated_duration] && props[:animated_duration] > 0

      @animation_time += delta_time
      
      if @animation_time >= props[:animated_duration]
        @animation_time = 0.0
        next_frame_name = props[:animated_next]
        
        if next_frame_name && !next_frame_name.empty? && tileset && tileset[next_frame_name.to_sym]
          old_frame = @current_frame
          @current_frame = next_frame_name.to_sym
          
          # Update properties to next frame's properties for continued animation
          next_tile = tileset[next_frame_name.to_sym]
          if next_tile && next_tile.props
            # Only update animation-related properties
            if next_tile.props[:animated_duration]
              self.props[:animated_duration] = next_tile.props[:animated_duration]
            end
            if next_tile.props[:animated_next]
              self.props[:animated_next] = next_tile.props[:animated_next]
            end
          end
          
          return old_frame != @current_frame # Signal that frame changed
        else
          # Stop animating if no valid next frame
          @current_frame = name
          return true
        end
      end
      
      return false # No frame change
    end

    def draw(position = nil)
      return unless tileset

      frame_to_draw = animated? ? @current_frame : name
      tileset.draw frame_to_draw, (position || self.position)
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
end
