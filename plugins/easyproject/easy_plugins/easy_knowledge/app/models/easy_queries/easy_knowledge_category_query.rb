class EasyKnowledgeCategoryQuery < EasyQuery

  def self.entity_css_classes(easy_knowledge_category, options={})
    easy_knowledge_category.css_classes(options[:level])
  end

  def self.permission_view_entities
    :view_easy_knowledge
  end

  def initialize_available_filters
    add_available_filter 'name', type: :text, order: 1
  end

  def initialize_available_columns
    on_column_group(l(:label_easy_knowledge)) do
      add_available_column 'name', sortable: "#{EasyKnowledgeCategory.table_name}.name"
    end
  end

  def default_list_columns
    super.presence || ['name']
  end

  def entity
    EasyKnowledgeCategory
  end

end
