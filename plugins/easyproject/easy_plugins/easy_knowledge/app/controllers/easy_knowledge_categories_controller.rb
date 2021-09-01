class EasyKnowledgeCategoriesController < EasyKnowledgeBaseController

  menu_item :easy_knowledge
  default_search_scope :easy_knowledge_categories
  accept_api_auth :index, :show, :create, :update, :destroy
  helper :custom_fields
  include CustomFieldsHelper

  before_action :find_category, :find_project, only: [:destroy, :edit, :show, :update]
  before_action :easy_knowledge_authorize_story_visible
  before_action :easy_knowledge_action_permissions
  before_action :authorize, only: [:index, :edit, :update, :new, :create, :show, :destroy], if: Proc.new { @project.present? }

  def index
    @categories_to_render ||= [:entity, :globals]                       # might be assigned in class descendants
    @entity ||= User.current if @categories_to_render.include?(:entity) # might be assigned in class descendants

    if @categories_to_render.include?(:no_category)
      retrieve_query(EasyKnowledgeStoryQuery)

      @query.entity_scope = index_query_entity_scope

      sort_init(@query.sort_criteria_init)
      sort_update({'id' => "#{EasyKnowledgeStory.table_name}.id"}.merge(@query.sortable_columns))

      prepare_easy_query_render
    end

    @easy_knowledge_categories = EasyKnowledgeCategory.visible.where(entity_type: nil).order(("#{EasyKnowledgeCategory.table_name}.lft")).to_a if @categories_to_render.include?(:globals)
    @easy_knowledge_entity_categories = @entity.easy_knowledge_categories.visible.order("#{EasyKnowledgeCategory.table_name}.lft").all if @entity

    @stories_counts = EasyKnowledgeStory.visible.joins(:easy_knowledge_categories).group('easy_knowledge_categories.id').count

    respond_to do |format|
      format.html do
        render_easy_query_html if @query
      end
      format.api
    end
  end

  def show
    retrieve_query(EasyKnowledgeStoryQuery)

    @project ||= @category.entity if @category && @category.entity.is_a?(Project)

    sort_init(@query.sort_criteria_init)
    sort_update({'id' => "#{EasyKnowledgeStory.table_name}.id"}.merge(@query.sortable_columns))

    @query.entity_scope = @category.easy_knowledge_stories

    set_pagination
    @stories = prepare_easy_query_render

    respond_to do |format|
      format.html {
        render_easy_query_html(@query, 'show')
      }
      format.csv { send_data(export_to_csv(@stories, @query), filename: get_export_filename(:csv, @query)) }
      format.pdf { send_file_headers! type: 'application/pdf', filename: get_export_filename(:pdf, @query) }
      format.xlsx { send_data(export_to_xlsx(@stories, @query), filename: get_export_filename(:xlsx, @query)) }
      format.atom { render_feed(@stories, title: l(:label_easy_knowledge_stories)) }
      format.api { render(template: 'easy_knowledge_stories/index') }
    end

  end

  def new
    @category ||= EasyKnowledgeCategory.new
    @category.entity_type ||= params[:entity_type] if params[:entity_type]
    @category.entity_id ||= params[:entity_id] if params[:entity_id]
    @project = @category.entity if @category.entity_type && @category.entity_type == 'Project'

    respond_to do |format|
      format.html
    end
  end

  def edit
    @project = @category.entity if @category.entity_type && @category.entity_type == 'Project'

    respond_to do |format|
      format.html
      format.js
    end
  end

  def create
    @category ||= EasyKnowledgeCategory.new
    @category.safe_attributes = params[:easy_knowledge_category]
    respond_to do |format|
      if @category.save
        flash[:notice] = l(:notice_successful_create)
        format.html { redirect_back_or_default({action: 'index'}) }
        format.api { render_api_ok }
      else
        format.html { render action: 'new' }
        format.api { render_validation_errors(@category) }
      end
    end
  end

  def update
    @category.safe_attributes = params[:easy_knowledge_category]
    respond_to do |format|
      if @category.save
        flash[:notice] = l(:notice_successful_update)
        format.html { redirect_back_or_default({action: 'index'}) }
        format.api { render_api_ok }
      else
        format.html { render action: 'edit' }
        format.api { render_validation_errors(@category) }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @category.easy_knowledge_stories.any?
        format.html {
          if params[:confirmed] && params[:destroy_option]
            case params[:destroy_option].to_sym
              when :all
                @category.easy_knowledge_stories.each(&:destroy)
              when :orphan
                possible_orphans = @category.easy_knowledge_stories.preload(:easy_knowledge_categories).each { |s| s.destroy if s.easy_knowledge_categories.count == 1 }
              when :move
                if params[:move_to]
                  move_to = EasyKnowledgeCategory.find_by(id: params[:move_to])
                  if move_to
                    move_to.easy_knowledge_story_ids = (move_to.easy_knowledge_story_ids + @category.easy_knowledge_story_ids).uniq
                    @category.easy_knowledge_story_ids.clear
                  else
                    return redirect_to(action: 'index', notice: l(:label_easy_knowledge_selected_category_was_not_found))
                  end
                end
              when :none
                # only destroy @category
              else
                flash[:error] = l(:text_easy_knowledge_category_destroy, count: @category.easy_knowledge_stories.count)
                return redirect_back_or_default action: 'index'
            end

            flash[:notice] = l(:notice_successful_delete)
            @category.destroy
            redirect_back_or_default action: 'index'
          else
            flash[:error] = l(:text_easy_knowledge_category_destroy, count: @category.easy_knowledge_stories.count)
            return redirect_back_or_default action: 'index'
          end
        }
        format.js {}
      else
        @category.destroy

        format.html {
          flash[:notice] = l(:notice_successful_delete)
          redirect_back_or_default({action: 'index'})
        }
        format.api { render_api_ok }
        format.js { render(js: "$('##{dom_id(@category)}').closest('tr').toggle('highlight').remove();") }
      end
    end
    # @category.destroy
  end

  protected

  # to override in descendants
  def index_query_entity_scope

  end

  private

  def find_category
    @category = EasyKnowledgeCategory.find(params[:id]) unless params[:id].blank?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_project
    @project = @category && @category.project
    @project ||= Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
