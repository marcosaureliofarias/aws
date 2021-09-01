class Numeric

  def roundup(nearest = 10)
    self % nearest == 0 ? self : self + nearest - (self % nearest)
  end

  def rounddown(nearest = 10)
    self % nearest == 0 ? self : self - (self % nearest)
  end

  def to_boolean
    self != 0
  end

end
