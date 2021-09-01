class EasyKnowledgeController < EasyKnowledgeBaseController

  helper :custom_fields

  menu_item :easy_knowledge
  default_search_scope :easy_knowledge_stories
  before_action :authorize_global, except: [:overview, :layout]
  before_action :cache_permissions
  before_action :find_project, only: [:show_toolbar, :show_as_tree]
  before_action :load_sidebar_variables
  before_action :find_story, only: [:show_as_tree]
  before_action :easy_knowledge_authorize_story_visible, only: [:show_as_tree]

  EasyExtensions::EasyPageHandler.register_for(self, {
    page_name: 'easy-knowledge-overview',
    path: proc { easy_knowledge_overview_path(t: params[:t]) },
    show_action: :overview,
    edit_action: :layout
  })

  def index
    params[:set_filter] = 0
    retrieve_query(EasyKnowledgeStoryQuery)
    @entities = @query.prepare_html_result

    query_recommended = @query.dup
    query_recommended.entity_scope = User.current.easy_knowledge_stories

    @dashboard_data = {
      :query_recommended => {
        :query => query_recommended,
        :entities => query_recommended.prepare_html_result(:order => "#{EasyKnowledgeStory.table_name}.created_on DESC", :limit => 10)
      },
      :query_newest => {
        :query => @query,
        :entities => @query.prepare_html_result(:order => "#{EasyKnowledgeStory.table_name}.created_on DESC", :limit => 10)
      },
      :query_hot => {
        :query => @query,
        :entities => @query.prepare_html_result(:order => "#{EasyKnowledgeStory.table_name}.storyviews DESC", :limit => 10)
      }
    }
    respond_to do |format|
      format.html {
        render_easy_query_html
      }
    end
  end

  def all_langfiles
    @translations = I18n.translate('.')
    respond_to do |format|
      format.api
    end
  end

  def show_as_tree
    @data = EasyKnowledgeBase.retrieve_data_for_tree(@project)
    favorite_story_ids = @project ? [] : User.current.favorite_easy_knowledge_stories.pluck(:id)
    @data[:favorite_story_ids] = favorite_story_ids

    respond_to do |format|
      format.html
      format.api
    end
  end

  def data
    params[:entities].each do |entity|

      @columns_output = {}
      @columns_output[entity[:entity]] = entity[:columns]
      @users = []
      case entity[:entity]
      when 'EasyKnowledgeCategory'
        @categories = EasyKnowledgeCategory.preload(:easy_knowledge_stories).visible.where(id: entity[:ids])
        @stories = @categories.flat_map{|category| category.easy_knowledge_stories.visible}

        user_ids = @categories.map(&:author_id)
        user_ids.concat @stories.flat_map(&:author_id)
        user_ids.uniq
        @users.concat(User.visible.where(id: user_ids))
        entity[:references].each do |reference|
          @columns_output[reference[:entity]] = reference[:columns] + ['id']
        end
      when 'User'
        @users.concat(User.visible.where(id: entity[:ids]))
      when 'EasyKnowledgeStory'
        @stories = EasyKnowledgeStory.visible.where(id: entity[:ids])
      when 'EasyKnowledgeProjects'
        @projects = Project.visible.has_module('easy_knowledge').pluck(:id, :name)
      when 'StoriesWithoutCategory'
        category_ids = EasyKnowledgeCategory.visible.pluck(:id)
        @stories_without_category = EasyKnowledgeStory.visible.eager_load(:easy_knowledge_story_categories).where("#{category_ids.any? ? "easy_knowledge_story_categories.category_id NOT IN (#{category_ids.join(', ')}) OR " : '' }easy_knowledge_story_categories.category_id IS NULL").distinct.pluck(:id, :name)
      when 'ProjectStoriesWithoutCategory'
        project = Project.find_by(id: entity['id'])
        @project_stories_without_category = project.easy_knowledge_stories.visible.where.not(id: EasyKnowledgeStory.joins(:easy_knowledge_categories).where(easy_knowledge_categories: {entity_type: 'Project', entity_id: project}).select('easy_knowledge_stories.id')).distinct.pluck(:id, :name) if project
      end
    end if params[:entities]
    respond_to do |format|
      format.api
    end
  end

  def search
    q = EasyKnowledgeStoryQuery.new
    limit = Setting.search_results_per_page.to_i
    limit = 20 if limit == 0

    condition = EasyKnowledgeStory.match_scope(:name, "%#{params[:easy_query_q]}%").to_sql
    @easy_knowledge_stories = q.entities(where: condition, limit: limit, order: :name)

    limit = limit - @easy_knowledge_stories.count
    if limit > 0
      story_ids = @easy_knowledge_stories.map(&:id)
      condition = EasyKnowledgeStory.match_scope(:description, "%#{params[:easy_query_q]}%").and(EasyKnowledgeStory.not_in_scope(:id, story_ids)).to_sql
      @easy_knowledge_stories = @easy_knowledge_stories | q.entities(where: condition, limit: limit, order: :name)
    end

    limit = limit - @easy_knowledge_stories.count
    if limit > 0
      story_ids = @easy_knowledge_stories.map(&:id)
      @easy_knowledge_stories_by_tags = EasyKnowledgeStory.additional_search_scope_by_tags(params[:easy_query_q], story_ids).visible
      @easy_knowledge_stories = @easy_knowledge_stories | @easy_knowledge_stories_by_tags
    end
    render(partial: 'easy_knowledge/easy_knowledge_toolbar_list_item', collection: @easy_knowledge_stories, as: :easy_knowledge_story)
  end

  def sidebar_categories
    render(:partial => 'easy_knowledge/sidebar_categories')
  end

  def show_toolbar
    user = User.current
    already_read_story_ids = EasyUserReadEntity.where(user_id: user.id, entity_type: 'EasyKnowledgeStory').pluck(:entity_id)
    recommend_story_ids = EasyKnowledgeAssignedStory.where(entity_type: 'Principal', entity_id: user.id).pluck(:story_id)
    unread_story_ids = recommend_story_ids - already_read_story_ids
    favorite_story_ids = User.current.favorite_easy_knowledge_stories.pluck(:id)
    story_ids = unread_story_ids | favorite_story_ids
    @unread_easy_knowledge_stories = story_ids.empty? ? [] : EasyKnowledgeStory.where(id: story_ids).distinct.to_a
    respond_to do |format|
      format.js
    end
  end

  private

  def load_sidebar_variables
    @grouped_projects = get_easy_knowledge_projects
    @grouped_user_categories = EasyKnowledgeCategory.category_by_user(User.current.id)
    @grouped_global_categories = EasyKnowledgeCategory.global
  end
end
