module EasyKnowledgeBase

  def self.retrieve_data_for_tree(project=nil)
    if project
      categories = EasyKnowledgeCategory.visible.where(entity_type: 'Project', entity_id: project)

      project_stories = project.easy_knowledge_stories.visible.to_a

      category_stories = categories.flat_map(&:easy_knowledge_stories).map(&:id)
      stories_without_category = project_stories.select{|story| !category_stories.include?(story.id)}
    else
      categories = EasyKnowledgeCategory.visible.to_a
      stories_without_category = []
    end
    return { categories: categories, stories_without_category: stories_without_category }
  end
end
