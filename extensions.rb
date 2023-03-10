# frozen_string_literal: true

require 'ruby2d' unless defined?(Ruby2D)
require 'pathname' unless defined?(Pathname)

# Original Class Methods
$orig_methods = {}
$array_append_listeners = {append:[]}

(Array.instance_methods - Object.instance_methods).each do |key|
  $orig_methods[Array] ||= {}
  $orig_methods[Array][key] = Array.instance_method key
end

# Add the ability to randomly choose an item from any array
class Array
  def self.add_listener(*_, &block)
    return unless block_given?

    $array_append_listeners[:append].append(block)
  end

  def append(*args)
    $array_append_listeners[:append].each do |callback|
      callback.call(self, *args)
    end
    $orig_methods[Array][:append].bind(self).call(*args)
  end

  def choose_one
    choice = rand(0...length)
    self[choice]
  end

  def first_of(&block)
    filtered = filter &block
    filtered.first
  end
end

def true?(value)
  ![false, 0, '0', 'f', 'F', 'false', 'FALSE', 'off', 'OFF'].include? value
end

def false?(value)
  !true? value
end

def make_truthy(value)
  true? value ? true : false
end

class Pathname
  def self.basename(path)
    Pathname.new(path).basename
  end
end

$default_font = 'assets/fonts/Gintronic-Regular.otf'
def shadowed_text(text, point, size = 20, font = nil)
  font = font || $default_font
  label = Text.new(text, x: point.x, y: point.y, font: font, size: size, z:10, color: 'white')
  shade = Text.new(text, x: point.x + 1, y: point.y + 1, font: font, size: size, z:9, color: 'black')

  Struct.new(:label, :shade) do
    def set_text(value)
      label.text = value
      shade.text = value
    end
  end.new(label, shade)
end

def find_gems(path)
  p = Pathname.new(path)
  if Dir.entries(p).include? "Gemfile"
    return Pathname.new(File::absolute_path(p))
  elsif p.root?
    return nil
  end
  return find_gems(p.parent)
end

$root_path = find_gems(Dir.getwd)
$font_path = $root_path.join("assets", "fonts")
$tiled_path = $root_path.join("assets", "tiled")
$image_path = $root_path.join("assets", "images")

$extensions_complete = true
