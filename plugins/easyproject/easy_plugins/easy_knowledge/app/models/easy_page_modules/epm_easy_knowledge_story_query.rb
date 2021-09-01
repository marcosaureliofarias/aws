class EpmEasyKnowledgeStoryQuery < EpmEasyQueryBase

  def runtime_permissions(user)
    user.allowed_to_globally?({controller: 'easy_knowledge_stories', action: 'index'})
  end

  def category_name
    @category_name ||= 'others'
  end

  def query_class
    EasyKnowledgeStoryQuery
  end

end
