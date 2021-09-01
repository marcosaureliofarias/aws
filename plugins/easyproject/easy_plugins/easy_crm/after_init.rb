EasyExtensions::PatchManager.register_easy_page_controller 'EasyCrmController'
EasyExtensions::PatchManager.register_easy_page_helper 'EasyCrmHelper'

EpmEasyContactQuery.register_to_scope(:project, :plugin => :easy_crm)
EpmEasyCrmCreateEasyCrmCaseButton.register_to_scope(:project, :plugin => :easy_crm)
EpmEasyCrmCaseQuery.register_to_all(:plugin => :easy_crm)
EpmEasyEntityActivityCrmCaseQuery.register_to_all(:plugin => :easy_crm)
EpmEasyCrmUserPerformance.register_to_page('easy-crm-overview', 'easy-crm-project-overview', :plugin => :easy_crm)
EpmEasyCrmPieChartFromCustomField.register_to_page('easy-crm-overview', 'easy-crm-project-overview', :plugin => :easy_crm)
EpmEasyCrmUserTarget.register_to_page('easy-crm-overview', 'easy-crm-project-overview', :plugin => :easy_crm)
EpmEasyCrmCasesCreateNew.register_to_all(:plugin => :easy_crm)


EasyExtensions::AfterInstallScripts.add do
  page = EasyPage.where(:page_name => 'easy-crm-project-overview').first
  page_template = page.default_template

  unless page_template
    page_template = EasyPageTemplate.create(:easy_pages_id => page.id, :template_name => 'Default template', :description => 'Default template', :is_default => true)

    EasyPageTemplateModule.create_template_module(page, page_template, EpmEasyCrmCaseQuery.first, 'top-left', HashWithIndifferentAccess.new, 1)
  end
end

EasyExtensions::AfterInstallScripts.add do
  if (page = EasyPage.find_by(page_name: 'easy-crm-overview'))
    page_template = page.default_template

    unless page_template
      page_template = EasyPageTemplate.create(:easy_pages_id => page.id, :template_name => 'Default template', :description => 'Default template', :is_default => true)

      EasyPageTemplateModule.create_template_module(page, page_template, EpmEasyCrmCaseQuery.first, 'top-left', HashWithIndifferentAccess.new, 1)
      EasyPageTemplateModule.create_template_module(page, page_template, EpmNoticeboard.first, 'top-left', HashWithIndifferentAccess.new(:text => '<h1><a class="easy-demo-tutor-youtube-link" href="https://www.youtube.com/watch?v=2lvOM3N0Jm4"><img alt="" src="http://www.devel.easyredmine.com/form_scripts/images/customers.png" style="border:0px solid black; float:left; height:79px; margin-bottom:0px; margin-left:0px; margin-right:0px; margin-top:0px; width:114px" /></a>' + EasyExtensions::EasyProjectSettings.app_name + ' CRM&nbsp;</h1>
<p>Welcome to ' + EasyExtensions::EasyProjectSettings.app_name + ' CRM - navigate yourself through tabs or starts with modules&nbsp;bellow. All is just demo data so feel free to do what you want.</p>
<p><span style="color:#FF8C00"><strong>Sales reps find bellow:</strong></span></p>
<ul>
	<li><strong>New leads assigned to you - this is what you should follow-up </strong>(at the end of day, this should be cleaned)</li>
	<li><strong>Contracts to close - these are opportunities you promised to close this week </strong>(all should be closed at the end of week)</li>
</ul>
<p><span style="color:rgb(255, 140, 0)"><strong>Sales managers&nbsp;find bellow:</strong></span></p>
<ul>
	<li><strong>Leads to assign - this is new meat you should distribute to sales reps&nbsp;</strong>(you should keep it as empty as possible)</li>
	<li><strong>Contracts to close over due&nbsp;&nbsp;</strong>(these are contracts that were promissed to be close and are not yet)</li>
</ul>'), 1)
    end

    EasyPageZoneModule.create_from_page_template(page_template) if !page.all_modules.exists?
  end
end

ActiveSupport.on_load(:easyproject, yield: true) do

  require 'easy_crm/hooks'
  require 'easy_crm/internals'
  require 'easy_crm/proposer'
  require 'easy_crm/menus'

  # To prevent circular dependency error
  require_dependency 'easy_crm_mail_handler'

  Redmine::MenuManager.map :admin_menu do |menu|
    menu.push :easy_crm,
              { controller: 'easy_crm_settings', action: 'index', tab: 'easy_crm_case_statuses' },
              html: { class: 'icon icon-crm-1' },
              if: Proc.new { |p| User.current.admin? },
              before: :settings
  end

  Redmine::MenuManager.map :admin_dashboard do |menu|
    menu.push :easy_crm,
              { controller: 'easy_crm_settings', action: 'index', tab: 'easy_crm_case_statuses' },
              html: { menu_category: 'extensions', class: 'icon icon-crm-1' },
              if: Proc.new { |p| User.current.admin? },
              before: :settings
  end

  Redmine::MenuManager.map :project_menu do |menu|
    menu.push :easy_crm, { :controller => 'easy_crm', :action => 'project_index' }, :param => :project_id, :caption => :label_easy_crm, :if => Proc.new { |p| User.current.allowed_to?(:view_easy_crms, p) }
  end

  Redmine::MenuManager.map :top_menu do |menu|
    menu.push :easy_crm, { :controller => 'easy_crm', :action => 'index', :project_id => nil },
              :caption => :label_easy_crm,
              :if => Proc.new { User.current.allowed_to_globally?(:view_easy_crms, {}) },
              :html => { :class => 'icon icon-crm-1' },
              :first => true
    menu.push :easy_crm_new, { :controller => 'easy_crm_cases', :action => 'new', :project_id => nil },
              :parent => :easy_crm,
              :caption => :button_easy_crm_new_case,
              :if => Proc.new { User.current.allowed_to_globally?(:edit_own_easy_crm_cases, {}) || User.current.allowed_to_globally?(:edit_easy_crm_cases, {}) }
    menu.push :easy_crm_find_by_worker, { :controller => 'easy_crm_cases', :action => 'find_by_worker' },
              :parent => :easy_crm,
              :caption => :label_easy_crm_find_by_worker,
              :html => { :remote => true },
              :if => Proc.new { User.current.allowed_to_globally?(:view_easy_crms, {}) }
  end

  Redmine::MenuManager.map :easy_project_top_menu do |menu|
    menu.push :easy_crm_case_new,
              { :controller => 'easy_crm_cases', :action => 'new' },
              :param => :project_id,
              :caption => :label_easy_crm_case_new,
              :html => { :class => 'button-3 icon icon-add' },
              :if => ->(project) {
                project.module_enabled?(:easy_crm)
              }
  end

  Redmine::AccessControl.map do |map|
    map.project_module :easy_crm do |pmap|

      pmap.permission :view_easy_crms, {
        :easy_crm => [:index, :project_index],
        :easy_crm_cases => [:index, :show, :context_menu, :find_by_worker, :render_tab, :sales_activities],
        :easy_crm_case_items => [:index, :show],
        :easy_crm_charts => [:user_performance_chart, :pie_chart_from_custom_field, :user_compare_chart],
        :easy_crm_kanban => [:show, :settings, :save_settings],
        :journals => [:diff],
      }, :read => true

      pmap.permission :manage_easy_crm_page, {
        :easy_crm => [:layout, :project_layout]
      }

      pmap.permission :edit_easy_crm_cases, {
        :easy_crm_cases => [:new, :create, :edit, :update, :toggle_description, :description_edit, :bulk_edit, :bulk_update, :merge_edit, :merge_update, :new_items_from_price_book, :update_easy_crm_case_items, :remove_related_invoice],
        :easy_crm_case_items => [:index, :show, :new, :create, :edit, :update, :destroy],
        :easy_crm_related_easy_contacts => [:index, :create, :destroy],
        :easy_crm_related_easy_invoices => [:index, :create, :destroy],
        :easy_crm_related_issues => [:index, :create, :destroy],
        :journals => [:new],
        :attachments => [:upload],
        :easy_price_book_products => [:search],
        :easy_crm_kanban => [:assign_entity],
        :my => [:create_crm_case_from_module]
      }

      pmap.permission :edit_own_easy_crm_cases, {
        :easy_crm_cases => [:new, :create, :edit, :update, :toggle_description, :bulk_edit, :bulk_update, :merge_edit, :merge_update, :update_easy_crm_case_items, :remove_related_invoice],
        :easy_crm_case_items => [:index, :show, :new, :create, :edit, :update, :destroy],
        :easy_crm_related_easy_contacts => [:index, :create, :destroy],
        :easy_crm_related_easy_invoices => [:index, :create, :destroy],
        :easy_crm_related_issues => [:index, :create, :destroy],
        :journals => [:new],
        :attachments => [:upload],
        :easy_price_book_products => [:search]
      }

      pmap.permission :delete_easy_crm_cases, { :easy_crm_cases => :destroy }

      pmap.permission :manage_easy_crm_settings, {
        :easy_crm_settings => [:project_index, :save_project_settings],
        :easy_crm_case_mail_templates => [:index, :show, :new, :create, :edit, :update, :destroy],
        :easy_crm_case_statuses => [:index, :show, :new, :create, :edit, :update, :destroy, :change]
      }

      pmap.permission :add_easy_crm_case_watchers, { :watchers => [:new, :create, :append, :autocomplete_for_user] }
      pmap.permission :view_easy_crm_case_watchers, {}, :read => true
      pmap.permission :delete_easy_crm_case_watchers, { :watchers => :destroy }
      pmap.permission :edit_crm_case_notes, { :journals => :edit }, :require => :loggedin
      pmap.permission :edit_own_crm_case_notes, { :journals => :edit }, :require => :loggedin
      pmap.permission :manage_easy_user_targets, {
        :easy_user_targets => [:bulk_edit, :bulk_update, :add_user, :remove_user, :index, :set_user_target_currency]
      }, global: true
    end
  end

end

RedmineExtensions::Reloader.to_prepare do

  Dir[File.dirname(__FILE__) + '/lib/easy_crm/easy_calendar/advanced_calendars/*.rb'].each { |file| require file } if Redmine::Plugin.installed?(:easy_calendar)

  EasySetting.map.boolean_keys(:easy_crm_case_query_includes_descendants, :show_easy_entity_activity_on_crm_case, :easy_crm_use_items, :show_description_on_crm_case)

  if Redmine::Plugin.installed?(:easy_mail_campaigns)
    require_dependency 'easy_mail_campaign_easy_crm_case'
  end

  if Redmine::Plugin.installed?(:easy_computed_custom_fields)
    Dir[File.dirname(__FILE__) + '/lib/easy_crm/easy_computed_custom_fields/computed_token_symbols/*.rb'].each { |file| require_dependency file }
    EasyComputedCustomFields::FieldFormats::EasyComputedToken.register_symbol(EasyComputedCustomFields::EasyCrmCaseTokenSymbol.new)
  end

  CustomFieldsHelper::CUSTOM_FIELDS_TABS << { :name => EasyCrmCaseCustomField.name, :partial => 'custom_fields/index', :label => :label_easy_crm_cases }
  CustomFieldsHelper::CUSTOM_FIELDS_TABS << { name: 'EasyCrmCountryValueCustomField', partial: 'custom_fields/index', label: :label_easy_crm_country_values }

  require_dependency 'easy_crm/easy_lookups/easy_lookup_easy_crm_case'
  EasyExtensions::EasyLookups::EasyLookup.map do |easy_lookup|
    easy_lookup.register 'EasyCrm::EasyLookups::EasyLookupEasyCrmCase'
  end

  Redmine::Search.map do |search|
    search.register :easy_crm_cases
  end

  EasyQuery.map do |query|
    query.register 'EasyCrmCaseQuery'
    query.register 'EasyCrmCaseItemQuery'
    query.register 'EasyCrmContactQuery'
    query.register 'EasyCrmCountryValueQuery'
    query.register 'EasyUserTargetQuery'
    query.register 'EasyEntityActivityCrmCaseQuery'
  end

  Redmine::Activity.map do |activity|
    activity.register :easy_crm_cases, { :class_name => %w(EasyCrmCase Journal), :default => false }
  end

  EasyCrmCase
  EasyCrmCaseItem
  EasyUserTarget

  TimeEntry.available_entity_types << 'EasyCrmCase'

  require_dependency 'easy_crm/easy_crm_case_merge_builder'

end
