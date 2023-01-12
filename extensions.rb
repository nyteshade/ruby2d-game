# frozen_string_literal: true

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
end

def true?(value)
  ![false, 0, '0', 'f', 'F', 'false', 'FALSE', 'off', 'OFF'].include? value
end

def false?(value)
  !true? value
end
