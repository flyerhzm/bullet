class String
  def bullet_class_name
    self.sub(/:[^:]*?$/, "")
  end
end
