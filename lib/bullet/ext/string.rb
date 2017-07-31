class String
  def bullet_class_name
    self.sub(/:[^:]*?$/, ''.freeze)
  end
end
