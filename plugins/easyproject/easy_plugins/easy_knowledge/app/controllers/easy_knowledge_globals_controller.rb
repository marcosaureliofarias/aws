class EasyKnowledgeGlobalsController < EasyKnowledgeCategoriesController

  menu_item :easy_knowledge
  default_search_scope :easy_knowledge_stories
  skip_before_action :find_project
  accept_api_auth :index, :show, :create, :update, :destroy

  def index
    @categories_to_render ||= [:globals]
    @easy_knowledge_categories = EasyKnowledgeCategory.visible.where(:entity_type => nil).order(:lft).all if !request.xhr?
    super
  end

  private

  def index_query_entity_scope
    t = EasyKnowledgeCategory.arel_table
    EasyKnowledgeStory.visible.where(:entity_type => nil).includes(:easy_knowledge_categories).references(:easy_knowledge_categories).where(t[:id].eq(nil))
  end

  def entity_visible?(entity_type, entity_id)
    entity_type ? super : User.current.allowed_to?(:manage_global_categories, nil, :global => true)
  end
end
