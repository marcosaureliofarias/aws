class EasyDisabledPrincipal < Principal

  def visible?(user = User.current)
    false
  end

  def active?
    false
  end

end