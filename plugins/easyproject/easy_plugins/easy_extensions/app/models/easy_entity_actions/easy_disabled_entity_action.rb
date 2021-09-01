class EasyDisabledEntityAction < EasyEntityAction
  def visible?(user = nil)
    false
  end

  def execute(entity)
    true
  end
end