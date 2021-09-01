class EasyDisabledAuthSource < AuthSource
  def editable?
    false
  end

  def test_connection
    raise
  end
end
