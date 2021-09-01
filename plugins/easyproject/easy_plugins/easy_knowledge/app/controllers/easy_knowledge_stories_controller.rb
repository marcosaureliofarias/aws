class EasyKnowledgeStoriesController < EasyKnowledgeBaseController

  menu_item :easy_knowledge
  default_search_scope :easy_knowledge_stories
  accept_api_auth :index, :show, :create, :update, :destroy, :update_story_category, :restore, :toggle_favorite

  before_action :find_entity, only: [:new]
  before_action :find_source_issue, only: [:create]
  before_action :find_project
  before_action :find_story, only: [:edit, :show, :update, :toggle_favorite, :add_comment, :diff, :render_tabs, :restore, :detail_partials_for_client, :update_story_category]
  before_action :find_stories, only: [:destroy, :assign_entities, :remove_from_entity, :mark_as_read]
  before_action :cache_permissions
  before_action :easy_knowledge_authorize_story_visible, only: [:show]
  before_action :easy_knowledge_authorize_stories_editable, only: [:edit, :destroy, :update, :restore, :update_story_category]
  before_action :easy_knowledge_authorize_create_permission, only: [:new, :create]
  before_action :easy_knowledge_authorize_stories_assignment_permission, only: [:assign_entities]
  before_action :find_category, only: [:update_story_category]
  before_action :find_version, only: [:restore]

  helper :attachments
  include AttachmentsHelper
  helper :issues
  include IssuesHelper
  helper :journals
  include JournalsHelper
  helper :repositories
  include RepositoriesHelper

  def index

    retrieve_query(EasyKnowledgeStoryQuery)

    @project = @category.entity if @category && @category.entity.is_a?(Project)

    sort_init(@query.sort_criteria_init)
    sort_update({'id' => "#{EasyKnowledgeStory.table_name}.id"}.merge(@query.sortable_columns))


    if @category
      @query.from_params({set_filter: 0})
      @query.additional_statement = "#{EasyKnowledgeStoryCategory.table_name}.category_id = #{@category.id}"
    end

    @stories = prepare_easy_query_render

    respond_to do |format|
      format.html {
        render_easy_query_html
      }
      format.csv  { send_data(export_to_csv(@stories, @query), filename: get_export_filename(:csv, @query)) }
      format.pdf  { send_file_headers! type: 'application/pdf', filename: get_export_filename(:pdf, @query) }
      format.xlsx { send_data(export_to_xlsx(@stories, @query), filename: get_export_filename(:xlsx, @query)) }
      format.atom { render_feed(@stories, title: l(:label_easy_knowledge_stories))}
      format.api
    end

  end

  def show
     @story.mark_as_read
     @story.add_storyview!

     @readers = @story.readers

    @users = @story.users.sorted
    @users -= @readers

    @journals = @story.journals.to_a
    @journals.reverse! if User.current.wants_comments_in_reverse_order?

    respond_to do |format|
      format.html
      format.api
    end
  end

  def new
    @story = if @entity
      build_from_entity
    else
      story = EasyKnowledgeStory.new
      story.safe_attributes = params[:easy_knowledge_story]
      story
    end
    @tags = get_tags

    @story.easy_knowledge_category_ids += Array(params[:category_id]) if params[:category_id]

    @can[:view_global_categories] = @can[:read_global_stories] || @can[:manage_global_categories]
    @can[:view_project_categories] = @can[:read_project_stories] || @can[:manage_project_categories]

    respond_to do |format|
      format.html
      format.js
    end
  end

  def edit
    # @grouped_categories = get_grouped_categories
    @tags = get_tags

    @can[:view_global_categories] = @can[:manage_global_categories] || @can[:read_global_stories]
    @can[:view_project_categories] = @can[:read_project_stories] || @can[:manage_project_categories]
    render action: (@story.editable? ? 'edit' : 'show')
  end

  def create
    @story = EasyKnowledgeStory.new
    @story.safe_attributes = params[:easy_knowledge_story]
    @tags = get_tags
    respond_to do |format|
      if @story.save
        project_assignable = User.current.allowed_to?(:manage_project_stories, @project) || User.current.allowed_to?(:create_project_stories, @project)
        if @project && project_assignable
          @project.easy_knowledge_stories |= [@story]
        end
        @story.issues << @source_issue if @source_issue
        Attachment.attach_files(@story, params[:attachments])
        @story.mark_as_read
        if @story.entity.blank? && !@story.easy_knowledge_categories.any?
          flash[:warning] = l(:warning_easy_knowledge_story_none_category_selected)
        end
        flash[:notice] = l(:notice_successful_create)
        format.html { redirect_back_or_default project_assignable ? polymorphic_path([@project, @story]) : @story }
        format.js {}
		    format.api { render action: 'show' }
      else
        format.html { render action: 'new' }
        format.js { render action: 'new' }
        format.api { render_validation_errors(@story) }
      end
    end
  end

  def update
    @story.safe_attributes = params[:easy_knowledge_story]
    respond_to do |format|
      if @story.save
        Attachment.attach_files(@story, params[:attachments])
        if @story.entity.blank? && !@story.easy_knowledge_categories.any?
          flash[:warning] = l(:warning_easy_knowledge_story_none_category_selected)
        end
        flash[:notice] = l(:notice_successful_update)
        format.html { redirect_back_or_default @project ? polymorphic_path([@project, @story]) : @story }
        format.api { render_api_ok }
      else
        format.html {
          # @grouped_categories = get_grouped_categories
          @tags = get_tags
          render action: 'edit'
        }
        format.api { render_validation_errors(@story) }
      end
    end
  end

  def destroy
    scope = EasyKnowledgeStory.where(id: params[:id] || params[:ids])
    if scope.any?
      scope.destroy_all
      flash[:notice] = l(:notice_successful_delete)
    else
      flash[:error] = l(:error_no_story_seleted)
    end
    respond_to do |format|
      format.html { redirect_back_or_default(easy_knowledge_overview_path) }
      format.api { render_api_ok }
    end
  end

  def add_comment
    @journal = Journal.new(journalized: @story, user: User.current, notes: params[:notes])
    respond_to do |format|
      if @journal.save
        @journals = @story.journals.to_a
        @journals.reverse! if User.current.wants_comments_in_reverse_order?
        format.js
        format.api {render_api_ok}
      else
        format.api {render_validation_errors(@journal)}
      end
    end
  end

  def diff
    old_story = @story.versions.find_by(version: params[:compare_version])
    return render_404 if !old_story.present?
    @current_version = @story.current_version
    @diff = Redmine::Helpers::Diff.new(@story.description, old_story.description)
    respond_to do |format|
      format.js
    end
  end

  def render_tabs
    case params[:tab]
      when 'comments'
        @journals = @story.journals.to_a
        @journals.reverse! if User.current.wants_comments_in_reverse_order?
        render partial: 'easy_knowledge_stories/tabs/comments'
      when 'history'
        render partial: 'easy_knowledge_stories/tabs/history'
      when 'readers'
        @readers = @story.readers
        @users = @story.users.sorted
        @users -= @readers
        render partial: 'easy_knowledge_stories/tabs/readers'
    end
  end

  def assign_entities
    if params[:entity_type]
      @entities = params[:entity_type].camelcase.constantize.where(id: params[:entity_ids])
      if params[:entity_type] == 'Group'
        @entities = @entities.collect { |p| p.users }.flatten.uniq
        params[:entity_type] = 'User'
      end
      @entities.each do |e|
        e.easy_knowledge_stories = (e.easy_knowledge_stories + Array(@easy_knowledge_stories)).uniq
      end
    end

    respond_to do |format|
      if @entities && @entities.any? && @easy_knowledge_stories.any?
        if params[:entity_type] == 'User'
          EasyKnowledgeMailer.deliver_recommended_stories(@easy_knowledge_stories, @entities)
          if @easy_knowledge_stories.count == 1
            @readers = @easy_knowledge_stories.first.readers
            @users = @easy_knowledge_stories.first.users.sorted
            @users -= @readers
          end
        end
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_to params[:back_url] || (@easy_knowledge_stories.count > 1 ? polymorphic_path(:easy_knowledge_stories) : polymorphic_path(@easy_knowledge_stories.first))
        }
        format.json {
          flash[:notice] = l(:notice_successfully_assignable_easy_knowledges, count: @easy_knowledge_stories.size)
          render(json: {notice: l(:notice_successfully_assignable_easy_knowledges, count: @easy_knowledge_stories.size)})
        }
        format.js
      else
        format.html {
          flash[:error] = l(:error_stories_cannot_be_assigned)
          redirect_to params[:back_url] || (@easy_knowledge_stories.count > 1 ? polymorphic_path([@project, :easy_knowledge_stories]) : polymorphic_path([@project, @easy_knowledge_stories.first]))
        }
        format.json {render(json: {error: l(:error_stories_cannot_be_assigned, count: @easy_knowledge_stories.size)})}
      end

    end
  end

  def remove_from_entity
    if params[:entity_type]
      @entity = params[:entity_type].camelcase.constantize.find(params[:entity_id])
      @entity.easy_knowledge_stories = (@entity.easy_knowledge_stories - Array(@easy_knowledge_stories))
    end

    respond_to do |format|
      format.html {
        flash[:notice] = l(:notice_successful_update)
        redirect_to params[:back_url] || (@easy_knowledge_stories.count > 1 ? polymorphic_path([@project, :easy_knowledge_stories]) : polymorphic_path([@project, @easy_knowledge_stories.first]))
      }
      format.js
    end
  end

  def toggle_favorite
    if @story.is_favorite?
      @story.unfavorite!
    else
      @story.favorite!
    end
    respond_to do |format|
      format.html {redirect_to(@story)}
      format.api {render_api_ok}
    end
  end

  def restore
    @story.revert_to! @version

    respond_to do |format|
      format.html { redirect_to easy_knowledge_story_path(@story) }
      format.api  { render_api_ok }
    end
  end

  def mark_as_read
    @easy_knowledge_stories.each do |story|
      story.mark_as_read
      story.add_storyview!
    end
    respond_to do |format|
      format.js
      format.api {render_api_ok}
    end
  end

  def update_story_category
    if @category
      if params['add']
        @story.categories << @category
      elsif params['remove']
        @story.categories.delete @category
      end
    end

    respond_to do |format|
      if @category && @story.save
        format.api {render_api_ok}
      else
        format.api {render_api_errors(l(:error_category_could_not_be_updated))}
      end
    end
  end

  private

  def find_entity
    if params[:easy_knowledge_story] && params[:easy_knowledge_story][:entity_id] && params[:easy_knowledge_story][:entity_type]
      @entity = params[:easy_knowledge_story][:entity_type].classify.constantize.find(params[:easy_knowledge_story][:entity_id])
    end
  rescue NameError, ActiveRecord::RecordNotFound
    render_404
  end

  def find_version
    if params[:version_id]
      @version = @story.versions.find_by(id: params[:version_id])
    elsif params[:version]
      @version = @story.versions.find_by(version: params[:version])
    end
    return render_404 unless @version
  end

  def find_source_issue
    @source_issue = Issue.find(params['source_issue_id']) if params['source_issue_id']
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_category
    @category = EasyKnowledgeCategory.find_by(id: params['category_id'])
  end

  def build_from_entity
    return if params[:easy_knowledge_story].nil? || @entity.nil?
    entity_type = params[:easy_knowledge_story][:entity_type]

    case entity_type
    when 'Issue'
      description = @entity.description
      journals = @entity.journals.with_notes.order(:created_on)
      description << '<hr />' if journals.any?
      journals.each do |journal|
        description << "<strong>#{journal.user}</strong> #{format_time(journal.created_on).html_safe}"
        description << "#{journal.notes}"
      end
      story = EasyKnowledgeStory.new
      story.safe_attributes = {name: @entity.subject, description: description}
    when 'Journal'
      story = EasyKnowledgeStory.new
      story.safe_attributes = {name: params[:easy_knowledge_story][:name], description: @entity.notes}
    else
      story = EasyKnowledgeStory.new
      story.safe_attributes = params[:easy_knowledge_story]
    end
    story
  end

end
