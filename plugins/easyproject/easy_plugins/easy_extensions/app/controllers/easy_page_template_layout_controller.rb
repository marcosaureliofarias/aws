class EasyPageTemplateLayoutController < ApplicationController
  include EasyControllersConcerns::PageLayout

  before_action :find_project
  before_action :find_page_template, :only => [:add_module, :order_module, :remove_module, :save_module]
  before_action :find_template_module, :only => [:clone_module, :clone_module_choose_target_tab]
  before_action :find_zone, :only => [:add_module, :order_module]
  before_action :add_tab_to_back_url, :only => [:save_module]

  def add_module
    begin
      available_module = EasyPageAvailableModule.find(params[:module_id])
    rescue ActiveRecord::RecordNotFound
      render_404
      return
    end

    @user    = User.current
    tab      = params[:t].to_i
    tab      = 1 if tab <= 0
    page_tab = EasyPageTemplateTab.find(params[:tab_id]) if params[:tab_id]
    page_tab ||= EasyPageTemplateTab.where(:page_template_id => @page_template.id, :entity_id => params[:entity_id], :position => tab).first

    template_module          = EasyPageTemplateModule.new(:easy_page_templates_id => @page_template.id, :easy_page_available_zones_id => @zone.id, :easy_page_available_modules_id => available_module.id,
                                                          :entity_id              => params[:entity_id], :tab => tab, :tab_id => (page_tab && page_tab.id), :settings => available_module.module_definition.default_settings || HashWithIndifferentAccess.new)
    template_module.position = 1
    template_module.save!

    page_params = create_page_params_for_easy_page_template(@page_template, @page, @user, params[:entity_id], params[:back_url] || original_url, true)

    @easy_page_modules_data                              = {}
    @easy_page_modules_data[template_module.module_name] = template_module.get_edit_data(@user)

    render :partial => 'easy_page_layout/page_module_edit_container', :locals => { :page_params => page_params, :page_module => template_module }
  end

  def clone_module
    new_template_module          = @template_module.dup
    new_template_module.position = @template_module.position.to_i
    if params[:tab_id]
      tab = EasyPageTemplateTab.find(params[:tab_id])
      new_template_module.tab      = tab.position
      new_template_module.tab_id   = tab.id
    end
    new_template_module.save!

    back_url = params[:back_url] || original_url

    render_single_easy_page_module(
        new_template_module, # page_module
        nil, # page_module_render_settings = nil
        nil, # page = nil
        User.current, # user = nil
        nil, # entity_id = nil
        back_url, # back_url = nil
        true, # edit = nil
        true, # with_container = false
    )
  end

  def clone_module_choose_target_tab
    respond_to do |format|
      format.js { render 'easy_page_layout/clone_module_choose_target_tab' }
    end
  end

  def remove_module
    pzm = EasyPageTemplateModule.find(params[:uuid].dasherize)
    pzm.destroy if pzm

    head :ok
  end

  def order_module
    remaining_modules_in_zone = (params["list-#{@zone.zone_definition.zone_name.dasherize}"] || [])
    tab                       = params[:t].to_i
    tab                       = 1 if tab <= 0

    remaining_modules_in_zone.each_with_index do |uuid, position|
      EasyPageTemplateModule.where(:uuid => uuid).update_all(:easy_page_available_zones_id => @zone.id, :position => position + 1)
    end

    head :ok
  end

  def save_grid
    grid_params = params.to_unsafe_hash
    data        = grid_params['page_modules']
    render_404 and return unless data

    modules = EasyPageTemplateModule.where(uuid: data.keys)
    modules.each do |epzm|
      epzm.settings['gridstack'] = data[epzm.uuid]
      epzm.save
    end

    head :ok
  end

  def save_module
    @page_template.template_modules(params[:entity_id], all_tabs: true).each do |zone_name, template_modules|
      template_modules.each do |template_module|
        next unless params[template_module.module_name]
        template_module.settings = params[template_module.module_name].to_unsafe_hash
        template_module.before_save
        template_module.save
      end
    end

    tabs          = ensure_tabs_for_settings(EasyPageTemplateTab, add: proc {
      EasyPageTemplateTab.add(@page_template, @entity_id)
    })
    all_page_tabs = EasyPageTemplateTab.page_template_tabs(@page_template, @entity_id)

    save_global_filters!(tabs)
    save_global_currency!(tabs)
    save_tabs_settings!(tabs, all_page_tabs)

    redirect_back_or_default(controller: 'my', action: 'page')
  end

  def get_tab_content
    @page_template = EasyPageTemplate.find(params[:page_template_id])
    @tab           = EasyPageTemplateTab.find(params[:tab_id]) if params[:tab_id]
    user           = User.find(params[:user_id]) if params[:user_id]

    @layout_style = @page_template.page_definition.layout_path

    render_action_as_easy_tab_content(@tab, @page_template, user, params[:entity_id], nil, true)
    render 'easy_page_layout/get_tab_content', layout: false
  end

  def show_tab
    @tab          = EasyPageTemplateTab.find(params[:tab_id]) if params[:tab_id]
    @selected_tab = params[:t].to_i if params[:t]
    @is_preloaded = params[:is_preloaded].to_s.to_boolean

    if @tab
      respond_to do |format|
        format.html {
          render :partial => 'common/easy_page_editable_tabs_inline_show', :locals => { :tab => @tab, :editable => true, :selected_tab => @selected_tab, :is_preloaded => @is_preloaded }
        }
        format.js {
          render 'easy_page_layout/show_tab'
        }
      end
    else
      head :ok
    end
  end

  def add_tab
    page_template = EasyPageTemplate.find(params[:page_template_id])
    entity_id     = params[:entity_id]

    @tab  = EasyPageTemplateTab.add(page_template, entity_id)
    @tabs = EasyPageTemplateTab.page_template_tabs(page_template, entity_id)
    @page = page_template.page_definition

    call_hook(:controller_easy_page_template_layout_add_tab, { :tab_id_to_copy => params[:tab_id_to_copy], :tab => @tab })

    respond_to do |format|
      format.js {
        if @tabs && @tabs.size > 0
          @layout_style = @page.layout_path.match(/\/?([^\/]+)$/)[1]
          render_action_as_easy_tab_content(@tab, page_template, nil, entity_id, nil, true)
          easy_page_context[:page_params][:current_tab] = @tab
          render 'easy_page_layout/add_tab'
        else
          head :ok
        end
      }
    end
  end

  def edit_tab
    tab = EasyPageTemplateTab.find(params[:tab_id]) if params[:tab_id]

    if tab
      render :partial => 'common/easy_page_editable_tabs_inline_edit', :locals => { :tab => tab, :editable => true, :is_preloaded => params[:is_preloaded] }
    else
      head :ok
    end
  end

  def save_tab
    tab = EasyPageTemplateTab.find(params[:tab_id]) if params[:tab_id]
    if params[:t]
      selected_tab = params[:t].to_i
    end

    if tab
      is_preloaded = params[:is_preloaded].to_s.to_boolean if params[:is_preloaded]
      if params[:name]
        if tab.easy_translations.any?
          locale                   = User.current.language.presence || I18n.locale
          tab.easy_translated_name = { locale => params[:name] }
        else
          tab.name = params[:name]
        end
      end
      tab.reorder_to_position = params[:reorder_to_position] if params[:reorder_to_position]
      tab.save

      respond_to do |format|
        format.html {
          render :partial => 'common/easy_page_editable_tabs_inline_show', :locals => { :tab => tab, :editable => true, :selected_tab => selected_tab }
        }
        format.js {
          @tab = tab; @selected_tab = selected_tab; @is_preloaded = is_preloaded
          render 'easy_page_layout/save_tab'
        }
      end
    else
      head :ok
    end
  end

  def remove_tab
    tab = EasyPageTemplateTab.find(params[:tab_id]) if params[:tab_id]
    if tab
      EasyPageTemplateModule.delete_modules(tab.page_template_definition, params[:entity_id], tab.id)
    end

    page_template = EasyPageTemplate.find(params[:page_template_id])
    entity_id     = params[:entity_id]

    tabs = EasyPageTemplateTab.page_template_tabs(page_template, entity_id)

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
          if tabs && tabs.size > 0 && tab && tab.position == params[:t].to_i
            js_script = "
              PageLayout.refreshTabs();
              PageLayout.tab_element.tabs('option', 'active', #{tab.position - 2});"
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

  private

  def find_project
    @project = Project.find(params[:project_id]) unless params[:project_id].blank?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_page_template
    @page_template = EasyPageTemplate.find(params[:id])
    @page          = @page_template.page_definition
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_zone
    @zone = EasyPageAvailableZone.find(params[:zone_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_template_module
    @template_module = EasyPageTemplateModule.find(params[:uuid])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
