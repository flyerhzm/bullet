class Object
  def bullet_ar_key
    if self.class.respond_to?(:primary_key) && self.class.primary_key
      "#{self.class}:#{self.send self.class.primary_key}"
    else
      "#{self.class}:#{self.id}"
    end
  end
end
