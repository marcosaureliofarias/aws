class EasyKnowledgeProjectsController < EasyKnowledgeCategoriesController

  menu_item :easy_knowledge
  default_search_scope :easy_knowledge_stories
  before_action :find_project, :only => [:index, :new, :create, :stories_tree]
  before_action :authorize, :only => [:index, :edit, :update, :new, :create, :show, :destroy, :stories_tree], :if => Proc.new { @project.present? }
  accept_api_auth :index, :show, :create, :update, :destroy

  def index
    @entity = @project
    @categories_to_render ||= [:entity, :no_category]
    super
  end

   def stories_tree
     @data = EasyKnowledgeBase.retrieve_data_for_tree(@project)
     @data[:favorite_story_ids] = []
   end

  def new
    @category = EasyKnowledgeCategory.new(:entity => @project)
    super
  end

  def create
    @category = EasyKnowledgeCategory.new(:entity => @project)
    super
  end

private

  def index_query_entity_scope
    in_cat = EasyKnowledgeStory.eager_load(:easy_knowledge_categories).where(easy_knowledge_categories: {entity_type: 'Project', entity_id: @entity.id})
    @entity.easy_knowledge_stories.visible.where.not(id: in_cat.pluck(:id))
  end

  def entity_visible?(entity_type, entity_id)
    entity_type ? super : (@project && User.current.allowed_to?(:manage_project_stories, @project))
  end
end
