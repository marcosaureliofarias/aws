class EasyPageLayoutController < ApplicationController
  include EasyControllersConcerns::PageLayout
  include EasyControllersConcerns::EasyPageJournals
  JOURNALIZED_ACTIONS = %w(add_module clone_module remove_module save_module add_tab remove_tab)

  before_action :find_project
  before_action :find_page, only: [:add_module, :remove_module, :order_module, :save_module, :add_tab, :remove_tab, :get_tab_content]
  before_action :find_zone, only: [:add_module, :order_module]
  before_action :find_available_module, only: [:add_module]
  before_action :find_zone_module, only: [:clone_module, :clone_module_choose_target_tab, :remove_module]
  before_action :find_user, only: [:clone_module, :save_module, :add_tab, :remove_tab, :get_tab_content]
  before_action :find_tab, only: [:add_module, :edit_tab, :save_tab, :remove_tab, :show_tab, :get_tab_content, :clone_module]
  before_action :add_tab_to_back_url, only: [:save_module]

  def add_module
    @user   = User.current
    user    = User.find(params[:user_id]) unless params[:user_id].nil?
    user_id = user.id unless user.nil?
    tab     = params[:t].to_i
    tab     = 1 if tab <= 0
    @tab    ||= EasyPageUserTab.where(page_id: @page.id, user_id: user_id, entity_id: params[:entity_id], position: tab).first

    page_module          = EasyPageZoneModule.new(
        easy_pages_id:                  @page.id,
        easy_page_available_zones_id:   @zone.id,
        easy_page_available_modules_id: @available_module.id,
        user_id:                        user_id,
        entity_id:                      params[:entity_id],
        tab:                            tab,
        tab_id:                         @tab&.id,
        settings:                       @available_module.module_definition.default_settings || HashWithIndifferentAccess.new
    )
    page_module.position = 1
    page_module.save!

    edit = params[:edit].nil? || params[:edit].to_boolean
    render_single_easy_page_module(page_module, nil, @page, user, nil, params[:back_url], edit, true, { project: @project })
  end

  def clone_module
    new_zone_module          = @zone_module.dup
    new_zone_module.position = @zone_module.position.to_i
    if @tab
      new_zone_module.tab      = @tab.position
      new_zone_module.tab_id   = @tab.id
    end
    new_zone_module.save!

    render_single_easy_page_module(
        new_zone_module, # page_module
        nil, # page_module_render_settings = nil
        nil, # page = nil
        @user, # user = nil
        nil, # entity_id = nil
        nil, # back_url = nil
        true, # edit = nil
        true, # with_container = false
        project: @project # page_context = {}
    )
  end

  def clone_module_choose_target_tab
    respond_to do |format|
      format.js
    end
  end

  def remove_module
    @zone_module.destroy if @zone_module

    head :ok
  end

  def order_module
    remaining_modules_in_zone = (params["list-#{@zone.zone_definition.zone_name.dasherize}"] || [])

    remaining_modules_in_zone.each_with_index do |uuid, position|
      EasyPageZoneModule.where(uuid: uuid).update_all(easy_page_available_zones_id: @zone.id, position: position + 1)
    end

    head 200
  end

  def save_module
    @page.user_modules(params[:user_id], params[:entity_id], nil, all_tabs: true).each do |zone_name, user_modules|
      user_modules.each do |user_module|
        next unless params[user_module.module_name]
        user_module.settings = params[user_module.module_name].to_unsafe_hash
        user_module.before_save
        user_module.save
      end
    end

    tabs          = ensure_tabs_for_settings(EasyPageUserTab, add: proc {
      EasyPageUserTab.add(@page, @user, params[:entity_id])
    })
    all_page_tabs = EasyPageUserTab.page_tabs(@page, @user, params[:entity_id])

    save_global_filters!(tabs)
    save_global_currency!(tabs)
    save_tabs_settings!(tabs, all_page_tabs)

    redirect_back_or_default(controller: 'my', action: 'page')
  end

  def layout_from_template
    begin
      page_template = EasyPageTemplate.find(params[:page_template_id].to_i)
    rescue ActiveRecord::RecordNotFound
      redirect_to params[:back_url]
      return
    end

    EasyPageZoneModule.create_from_page_template(page_template, params[:user_id], params[:entity_id])
    flash[:notice] = l(:notice_template_successful_applied)

    redirect_back_or_default(root_path)
  end

  def layout_from_template_selecting_projects
    respond_to do |format|
      format.html { render :layout => 'base' }
    end
  end

  def layout_from_template_add_replace
    @page = EasyPage.find_by(id: params[:page_id])

    respond_to do |format|
      format.js
    end
  end

  def layout_from_template_selected_projects
    begin
      page_template = EasyPageTemplate.find(params[:page_template_id].to_i)
    rescue ActiveRecord::RecordNotFound
      redirect_back_or_default(my_page_path)
      return
    end

    begin
      projects = Project.find(params[:projects])
    rescue ActiveRecord::RecordNotFound
      return render_404
    end

    projects.each do |project|
      replace_or_add_tabs(page_template, nil, project.id)
    end

    flash[:notice] = l(:notice_template_successful_applied)
    redirect_back_or_default(:controller => 'my', :action => 'page')
  end

  def layout_from_template_selecting_users
    @users  = User.active.sorted
    @groups = Group.joins(:users).where(:users_users => { :status => User::STATUS_ACTIVE }).distinct.sorted

    respond_to do |format|
      format.html { render :layout => 'base' }
    end
  end

  def layout_from_template_selected_users
    begin
      page_template = EasyPageTemplate.find(params[:page_template_id].to_i)
    rescue ActiveRecord::RecordNotFound
      redirect_back_or_default({ :controller => 'easy_pages' })
      return
    end

    if params[:users]
      User.where(:id => params[:users]).each do |user|
        replace_or_add_tabs(page_template, user, params[:entity_id])
      end
    end

    flash[:notice] = l(:notice_template_successful_applied)
    redirect_back_or_default(:controller => 'my', :action => 'page')
  end

  def layout_from_template_built_in
    page_template = EasyPageTemplate.find_by(id: params[:page_template_id])
    return redirect_back_or_default(easy_pages_path) unless page_template

    replace_or_add_tabs(page_template)

    flash[:notice] = l(:notice_template_successful_applied)
    redirect_back_or_default(my_page_path)
  end

  def layout_from_template_to_all
    begin
      page_template = EasyPageTemplate.find(params[:page_template_id].to_i)
    rescue ActiveRecord::RecordNotFound
      redirect_to params[:back_url]
      return
    end
    page    = page_template.page_definition
    actions = params[:actions].to_s.split(',')

    User.all.each do |user|
      EasyPageZoneModule.create_from_page_template(page_template, user.id, params[:entity_id])
    end if actions.include?('users')

    Redmine::Hook.call_hook(:controller_easy_page_layout_layout_from_template_to_all, { :page_template => page_template, :page => page, :actions => actions })

    flash[:notice] = l(:notice_template_successful_applied)
    redirect_back_or_default(:controller => 'my', :action => 'page')
  end

  def save_grid
    grid_params = params.to_unsafe_hash
    unless data = grid_params['page_modules']
      head :ok
      return
    end

    modules = EasyPageZoneModule.where(uuid: data.keys)
    modules.each do |epzm|
      epzm.settings['gridstack'] = data[epzm.uuid]
      epzm.save
    end

    head :ok
  end

  def get_tab_content
    @layout_style = @page.layout_path

    if @tab
      render_action_as_easy_tab_content(@tab, @page, @user, params[:entity_id], nil, true)
      render layout: false
    else
      head :ok
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def show_tab
    @selected_tab = params[:t].to_i if params[:t]
    is_preloaded  = params[:is_preloaded].to_s.to_boolean

    if @tab
      respond_to do |format|
        format.html { render partial: 'common/easy_page_editable_tabs_inline_show', locals: { tab: @tab, editable: true, selected_tab: @selected_tab, is_preloaded: is_preloaded } }
        format.js { @is_preloaded = is_preloaded }
      end
    else
      head :ok
    end
  end

  def add_tab
    entity_id = params[:entity_id]
    @tab      = EasyPageUserTab.add(@page, @user, entity_id)
    @tabs     = EasyPageUserTab.page_tabs(@page, @user, entity_id)

    call_hook(:controller_easy_page_layout_add_tab, { tab_id_to_copy: params[:tab_id_to_copy], tab: @tab, user_id: params[:user_id] })

    if params[:tab_id_to_copy]
      tab = EasyPageUserTab.find_by(id: params[:tab_id_to_copy])
      return render_404 if tab.nil?

      @tab.update_column(:settings, tab.settings)

      tab.user_tab_modules.each do |_position, modules|
        modules.each do |epzm|
          page_module = EasyPageZoneModule.new(easy_pages_id:                  tab.page_id,
                                               easy_page_available_zones_id:   epzm.easy_page_available_zones_id,
                                               easy_page_available_modules_id: epzm.easy_page_available_modules_id,
                                               user_id:                        @user&.id || epzm.user_id,
                                               entity_id:                      epzm.entity_id,
                                               position:                       epzm.position,
                                               settings:                       epzm.settings,
                                               tab_id:                         @tab.id)
          page_module.save!
        end
      end
    end

    respond_to do |format|
      format.js {
        if @tabs && @tabs.size > 0
          @layout_style = @page.layout_path.match(/\/([^\/]+)$/)[1]
          render_action_as_easy_tab_content(@tab, @page, @user, entity_id, nil, true)
          easy_page_context[:page_params][:current_tab] = @tab
        else
          head :ok
        end
      }
    end
  end

  def edit_tab
    if @tab
      render partial: 'common/easy_page_editable_tabs_inline_edit', locals: { tab: @tab, editable: true, is_preloaded: params[:is_preloaded] }
    else
      head :ok
    end
  end

  def save_tab
    if params[:t]
      selected_tab = params[:t].to_i
    end
    is_preloaded = params[:is_preloaded].to_s.to_boolean

    if @tab
      if params[:name]
        if @tab.easy_translations.any?
          locale                    = User.current.language.presence || I18n.locale
          @tab.easy_translated_name = { locale => params[:name] }
        else
          @tab.name = params[:name]
        end
      end
      @tab.reorder_to_position = params[:reorder_to_position] if params[:reorder_to_position]
      @tab.save
      respond_to do |format|
        format.html { render partial: 'common/easy_page_editable_tabs_inline_show', locals: { tab: @tab, editable: true, selected_tab: selected_tab, is_preloaded: is_preloaded } }
        format.js { @selected_tab = selected_tab; @is_preloaded = is_preloaded }
        format.json { head :ok }
      end
    else
      head :ok
    end
  end

  def remove_tab
    if @tab
      EasyPageZoneModule.delete_modules(@tab.page_definition, params[:user_id], params[:entity_id], @tab.id)
    end

    entity_id = params[:entity_id]
    tabs      = EasyPageUserTab.page_tabs(@page, (@user && @user.id), entity_id)

    if request.xhr?
      respond_to do |format|
        format.html {
          if tabs && tabs.size > 0
            selected_tab = params[:t].to_i
            selected_tab = 1 if selected_tab <= 0

            render(:partial => 'common/easy_page_editable_tabs', :locals => { :tabs => tabs, :editable => true, :selected_tab => selected_tab })
          else
            head :ok
          end
        }
        format.js {
          if tabs && tabs.size > 0 && @tab && @tab.id == params[:tab_id].to_i
            js_script = "
              PageLayout.tab_element.easytabs('select', '#easy_jquery_tab_panel-#{tabs.first.id}');"
          elsif tabs && tabs.size < 1
            original_url = CGI.unescape(params[:original_url])
            js_script    = "window.location.href='#{original_url}';"
          end
          if js_script
            render :status => :ok, :plain => js_script
          else
            head :ok
          end
        }
      end
    else
      original_url = CGI.unescape(params[:original_url])
      original_url.gsub!(/tab=\d+/, '')
      redirect_to(original_url)
    end
  end

  def get_group_entities
    user = User.current
    return render_404 unless (page_module = EasyPageZoneModule.find_by_uuid(params[:page_module_id]))
    data  = page_module.get_show_data(user, params[:query], :project => @project, :load_group => loading_group)
    query = data[:query]
    sort_init(query.sort_criteria_init)
    sort_update(query.sortable_columns, "#{self.sort_name}_#{params[:page_module_id]}")

    if prepare_easy_query_render(query, order: query.sort_criteria_to_sql_order.presence) && loading_group?
      render_easy_query_html(query)
    else
      render :inline => l(:label_easy_page_module_settings_missing)
    end
  end

  def toggle_members
    group       = Group.find(params[:group_id])
    user_fields = group.users.map { |user| "users_#{user.id}" }
    render :js => "fields = #{user_fields.to_json}; $(fields).each(function(f) {EASY.utils.toggleCheckbox(fields[f])})"
  end

  private

  def replace_or_add_tabs(page_template, user = nil, entity_id = nil)
    case params[:method]
    when 'replace'
      EasyPageZoneModule.create_from_page_template(page_template, user&.id, entity_id)
    when 'add_tabs'
      page ||= params[:easy_pages_id] ? EasyPage.find_by(id: params[:easy_pages_id]) : page_template.page_definition
      tabs = EasyPageUserTab.page_tabs(page, user, entity_id)
      EasyPageUserTab.add(page, user, entity_id) if tabs.empty?

      EasyPageZoneModule.add_from_page_template(page_template, user, entity_id)
    end
  end

  def find_available_module
    @available_module = EasyPageAvailableModule.find(params[:module_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_project
    @project = Project.find(params[:project_id]) unless params[:project_id].blank?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_page
    @page = EasyPage.find(params[:page_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_zone
    @zone = EasyPageAvailableZone.find(params[:zone_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_zone_module
    @zone_module = EasyPageZoneModule.find(params[:uuid].dasherize)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_user
    @user = User.find(params[:user_id]) unless params[:user_id].nil?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_tab
    @tab = EasyPageUserTab.find(params[:tab_id]) unless params[:tab_id].nil?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
