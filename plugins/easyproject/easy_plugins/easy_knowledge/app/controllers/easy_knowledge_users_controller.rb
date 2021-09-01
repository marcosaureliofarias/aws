class EasyKnowledgeUsersController < EasyKnowledgeCategoriesController

  menu_item :easy_knowledge
  default_search_scope :easy_knowledge_stories
  skip_before_action :find_project
  accept_api_auth :index, :show, :create, :update, :destroy

  before_render only: [:index] do
    #@stories[nil][:entities].delete_if{|e|(e.easy_knowledge_category_ids & @entity.easy_knowledge_category_ids).size > 0} if @stories && @stories[nil]
    @entities = @entities.to_a
    @entities.delete_if{|e| (e.easy_knowledge_category_ids & @entity.easy_knowledge_category_ids).size > 0}
  end

  def index
    @entity = User.current
    @categories_to_render = [:entity, :no_category]
    super
  end

  def new
    @category = EasyKnowledgeCategory.new(entity: User.current)
    super
  end

  def create
    @category = EasyKnowledgeCategory.new(entity: User.current)
    super
  end

private

  def index_query_entity_scope
    t = EasyKnowledgeStory.arel_table
    s = EasyKnowledgeAssignedStory.arel_table
    # tc = EasyKnowledgeCategory.arel_table

    EasyKnowledgeStory.includes([:easy_knowledge_assigned_stories, :easy_knowledge_categories]).references([:easy_knowledge_assigned_stories, :easy_knowledge_categories])
      .where(t[:author_id].eq(@entity.id).or(t[:entity_type].eq('Principal').and(t[:entity_id].eq(@entity.id)).or(s[:entity_type].eq('Principal').and(s[:entity_id].eq(@entity.id)))))
  end

  def entity_visible?(entity_type, entity_id)
    entity_type ? super : User.current.allowed_to?(:manage_user_stories, nil, :global => true)
  end
end
