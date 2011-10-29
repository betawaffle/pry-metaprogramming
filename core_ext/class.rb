class Class
  def singleton?
    self != ancestors.first
  end
end
