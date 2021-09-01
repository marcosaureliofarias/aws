class EasyDisabledQuery < EasyQuery

  def entity_easy_query_path(options)
  end

  def visible?(user = User.current)
    false
  end

end
