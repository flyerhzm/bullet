# frozen_string_literal: true

class Object
  def bullet_key
    "#{self.class}:#{primary_key_value}"
  end

  def primary_key_value
    if self.class.respond_to?(:primary_keys) && self.class.primary_keys
      self.class.primary_keys.map { |primary_key| send primary_key }.join(','.freeze)
    elsif self.class.respond_to?(:primary_key) && self.class.primary_key
      send self.class.primary_key
    else
      id
    end
  end
end
