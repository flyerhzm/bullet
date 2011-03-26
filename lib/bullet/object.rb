class ActiveRecord::Base
  def to_bullet_object
    ret = Bullet::Object.new
    ret[self.class.name] = self.id
    ret
  end
end

class Array
  def to_bullet_object
    if self.first.is_a? ActiveRecord::Base
      ret = Bullet::Object.new
      ret[self.first.class.name] = self.collect(&:id)
      ret
    else
      self
    end
  end
end

module Bullet
  class Object < Hash
  end
end
