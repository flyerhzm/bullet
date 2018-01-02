class String
  def bullet_class_name
    sub(/:[^:]*?$/, ''.freeze)
  end
end
