class Object
  def bullet_ar_key
    if self.is_a? ActiveRecord::Base
      "#{self.class}:#{self.send self.class.primary_key}"
    else
      "#{self.class}:#{self.id}"
    end
  end
end
