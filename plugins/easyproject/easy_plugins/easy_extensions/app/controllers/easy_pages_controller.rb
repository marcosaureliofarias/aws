class EasyPagesController < ApplicationController

  before_action -> { require_admin_or_lesser_admin(:easy_pages_administration) }, except: [:custom_easy_page, :custom_easy_page_layout]
  before_action -> { find_easy_page_by(id: params[:id]) }, only: [:show, :edit, :update, :destroy]
  before_action :find_page_from_identifier, only: [:custom_easy_page, :custom_easy_page_layout]

  EasyExtensions::EasyPageHandler.register_for(self, {
      path:        proc { url_for(controller: 'easy_pages', action: 'custom_easy_page', identifier: @page.identifier, t: params[:t]) },
      show_action: :custom_easy_page,
      edit_action: :custom_easy_page_layout
  })

  layout proc { |_| ['index', 'built_in'].include?(action_name) ? 'admin' : 'base' }

  def index
    @query_options   = { hascontextmenu: false }
    @sidebar_buttons = %i[saved_queries built_in]
    index_for_easy_query EasyPageQuery, [['identifier', 'asc']]
  end

  def built_in
    retrieve_query(EasyPageQuery)

    @query.entity_scope = EasyPage.built_in
    @query.column_names = [:translated_name]
    @entities           = @query.entities
    @entities.sort_by!(&:translated_name)
    @query_options   = { hascontextmenu: false, render_index: false, table_class: 'built-in-easy-pages' }
    @custom_title    = l('easy_pages.label_built_in')
    @sidebar_buttons = %i[overview]

    render action: :index
  end

  def show
  end

  def new
    @page                 = EasyPage.new
    @page.safe_attributes = params[:easy_page]
  end

  def create
    @page                 = EasyPage.new
    @page.safe_attributes = params[:easy_page]
    @page.layout_path     = EasyPage::PAGE_LAYOUTS[params[:page_layout_identifier]] && EasyPage::PAGE_LAYOUTS[params[:page_layout_identifier]][:path]
    @page.page_name       = EasyPage::CUSTOM_PAGE
    @page.is_user_defined = true

    case params[:page_scope_identifier]
    when 'nothing'
      @page.page_scope = nil
    else
      @page.page_scope = params[:page_scope_identifier]
    end

    if @page.save
      @page.install_registered_modules

      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_create)
          redirect_to(:action => 'index')
        }
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
      end
    end
  end

  def edit
    @page.safe_attributes = params[:easy_page]
    prepare_journals
  end

  def update
    @page.init_journal(User.current)
    @page.safe_attributes = params[:easy_page]

    if @page.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_back_or_default(action: 'index')
        }
      end
    else
      respond_to do |format|
        format.html do
          prepare_journals
          render action: 'edit'
        end
      end
    end
  end

  def destroy
    @page.destroy

    respond_to do |format|
      format.html {
        flash[:notice] = l(:notice_successful_delete)
        redirect_to(:action => 'index')
      }
    end
  end

  protected

  def edit_layout_action
    'custom_easy_page_layout'
  end

  private

  def find_page_from_identifier
    @page = EasyPage.find_by(identifier: params[:identifier])

    render_404 if @page.nil? || !@page.is_user_defined?
  end

  def prepare_journals
    return unless @page.page_scope.nil?
    journal_limit  = EasySetting.value('easy_extensions_journal_history_limit')
    journals_scope = @page.journals
    @journal_count = journals_scope.count
    @journals      = journals_scope.reorder("#{Journal.table_name}.id ASC").limit(journal_limit).to_a
    @journals.reverse! if User.current.wants_comments_in_reverse_order?
  end

end
