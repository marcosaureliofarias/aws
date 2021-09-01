class EasyKnowledgeStoryCustomField < CustomField

  def type_name
    :label_easy_knowledge_stories
  end

  def form_fields
    [:is_filter, :searchable, :is_required]
  end

end
