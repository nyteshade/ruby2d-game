require 'ruby2d/core' unless defined? Ruby2D
require_relative 'game_point' unless defined? Game::Point

module Game
  Tile = Struct.new(:name, :position, :passable, :props, :tileset) do
    include Ruby2D::Renderable
    attr_accessor :current_display_name, :animation_start_time, :animated

    def x = position.x
    def y = position.y
    def z = position.z

    def x=(value); position.x = value; end
    def y=(value); position.y = value; end
    def z=(value); position.z = value; end

    def initialize(name, position = Point.new, passable = true, props = {}, tileset = nil)
      super
      @current_display_name = name
      @animation_start_time = Time.now.to_f
      @next_frame = nil
      @animated = props[:animated]
    end

    def animated?
      @animated == true
    end

    def update_animation
      return unless animated?

      # Get animation properties
      duration = props[:animated_duration] || 0.2  # Default to 0.2 seconds

      # Check if it's time to advance to the next frame
      current_time = Time.now.to_f
      elapsed = current_time - @animation_start_time

      if elapsed >= duration
        next_frame = next_animation_frame

        if next_frame
          # Store old display name to detect changes
          old_display = @current_display_name

          # Switch to the next frame
          @current_display_name = next_frame.name
          @animation_start_time = current_time
        else
          @animated = false
        end

        # Return true if the frame changed
        return old_display != @current_display_name
      end

      # No change occurred
      return false
    end

    def set_next_animation_frame(next_name)
      props[:animated_next] = next_name
      #@next_frame = nil  # Invalidate the cache
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

    def display_name
      animated? ? @current_display_name : name
    end

    def draw(position = nil)
      return unless tileset
      tileset.draw display_name, (position || self.position)
    end

    def next_animation_frame
      # REMOVE this caching code
      # @next_frame ||= begin
      #   next_name = props[:animated_next]
      #   return nil if next_name.nil? || next_name.empty?
      #
      #   if tileset && tileset.metadata[:symbols].has_key?(next_name.to_sym)
      #     tileset.metadata[:symbols][next_name.to_sym]
      #   else
      #     nil
      #   end
      # end

      # Replace with direct lookup
      next_name = props[:animated_next]
      return nil if next_name.nil? || next_name.empty?

      if tileset && tileset.metadata[:symbols].has_key?(next_name.to_sym)
        tileset.metadata[:symbols][next_name.to_sym]
      else
        nil
      end
    end

    def reset_animation
      @current_display_name = name
      @animation_start_time = Time.now.to_f
      #@next_frame = nil  # Clear the cache
      @animated = props[:animated]
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

  def print_animation_sequence
    return puts "Tile #{name} is not animated" unless props[:animated]

    sequence = [name.to_s]
    current_name = props[:animated_next]
    visited = {name => true}

    while !current_name.nil? && !current_name.empty?
      sequence << current_name

      # Prevent infinite loops
      if visited[current_name.to_sym]
        sequence << "... (loops back to #{current_name})"
        break
      end
      visited[current_name.to_sym] = true

      # Get the next tile in the sequence
      current_tile = tileset&.metadata[:symbols][current_name.to_sym]
      break unless current_tile

      current_name = current_tile.props[:animated_next]
    end

    puts "Animation sequence for #{name}: #{sequence.join(' → ')}"
    puts "Animation duration: #{props[:animated_duration]} seconds"
    puts "Current display frame: #{@current_display_name}"
  end
end
