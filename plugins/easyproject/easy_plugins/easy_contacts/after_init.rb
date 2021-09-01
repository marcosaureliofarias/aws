# encoding: utf-8
Mime::Type.register 'text/directory', :dir

EasyExtensions::PatchManager.register_easy_page_controller 'EasyContactsController'
EasyExtensions::PatchManager.register_easy_page_controller 'EasyContactGroupsController'
EasyExtensions::PatchManager.register_easy_page_helper 'EasyContactsHelper'

EpmEasyContactQuery.register_to_all(:plugin => :easy_contacts)
EpmEasyContactCreateButton.register_to_page('easy-contacts-overview', :plugin => :easy_contacts)
EpmGroupOfContactsButton.register_to_page('easy-contacts-overview', :plugin => :easy_contacts)
EpmImportContactsButton.register_to_page('easy-contacts-overview', :plugin => :easy_contacts)
EpmMyContactsButton.register_to_page('easy-contacts-overview', :plugin => :easy_contacts)
EpmProjectContactsOverview.register_to_scope(:project, :plugin => :easy_contacts)
EpmUserContactsOverview.register_to_scope(:user, :plugin => :easy_contacts)
EpmEasyContactsCreateNew.register_to_all(:plugin => :easy_contacts)

EasyExtensions::AfterInstallScripts.add do
  page = EasyPage.where(:page_name => 'easy-contacts-overview').first
  page_template = page.default_template

  unless page_template
    page_template = EasyPageTemplate.create(:easy_pages_id => page.id, :template_name => 'Default template', :description => 'Default template', :is_default => true)

    EasyPageTemplateModule.create_template_module(page, page_template, EpmNoticeboard.first, 'top-left', HashWithIndifferentAccess.new(:text => '<h1>Contacts</h1>
<p><a class="easy-demo-tutor-youtube-link" href="https://www.youtube.com/watch?v=9IB6j7PtLHU"><img alt="" src="data:image/png;base64,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" style="border:0px solid black; float:left; height:79px; margin-bottom:0px; margin-left:20px; margin-right:20px; margin-top:0px; width:114px" /></a></p>
<p>This ' + EasyExtensions::EasyProjectSettings.app_name + ' plugin is a part of <strong>Customer management package</strong>. It is database of contacts that<span style="color:#FF8C00"><strong> connects together all of Customer management plugins - CRM &amp; Invoicing &amp; Help Desk.</strong></span></p>'), 1)
  end

  EasyPageZoneModule.create_from_page_template(page_template) if !page.all_modules.exists?
end

ActiveSupport.on_load(:easyproject, yield: true) do
  require 'easy_contacts/hooks'
  require 'easy_contacts/proposer'

  Redmine::MenuManager.map :top_menu do |menu|
    menu.push(:easy_contacts, {:controller => 'easy_contacts', :action => 'overview', :project_id => nil}, {
      :caption => :menu_easy_contacts,
      :if => Proc.new { User.current.allowed_to_globally?(:view_easy_contacts, {}) },
      :first => :true,
      :html => {:class => 'icon icon-group'}
    })
    menu.push(:easy_contacts_new, :new_easy_contact_path, {
      :parent => :easy_contacts,
      :if => Proc.new { User.current.allowed_to_manage_easy_contacts? },
      :caption => :'easy_contacts_toolbar.new_contact'
    })
    menu.push(:easy_contacts_find_by_easy_query, {controller: 'easy_queries', action: 'find_by_easy_query', :type => 'EasyContactQuery', :title => :button_easy_contact_by_easy_query}, {
      :parent => :easy_contacts,
      :if => Proc.new { User.current.allowed_to_globally?(:view_easy_contacts, {}) },
      :html => {:remote => true},
      :caption => :button_easy_contact_by_easy_query
    })
  end

  Redmine::MenuManager.map :project_menu do |menu|
    menu.push :easy_contacts, {:controller => 'easy_contacts', :action => 'index', :set_filter => 0}, :param => :project_id, :caption => :label_easy_contacts, :if => Proc.new { |p| User.current.allowed_to?(:view_easy_contacts, p) && p.module_enabled?(:easy_contacts) }
  end

  Redmine::MenuManager.map :easy_servicebar_items do |menu|
    menu.push(:easy_contacts_toolbar, :show_easy_contacts_toolbar_path, :html => {
      :class => 'icon-user',
      :id => 'easy_contacts_toolbar_trigger',
      :title => EasyExtensions::MenuManagerProc.new { I18n.t(:label_easy_contacts) },
      :remote => true
    },
              :caption => '',
              :if => lambda { |project| User.current.allowed_to_globally?(:view_easy_contacts, {}) }
    )
  end

  Redmine::MenuManager.map :easy_crm_contacts_page_menu do |menu|
    menu.push :easy_contacts_new_contact, {:controller => 'easy_contacts', :action => 'new'},
              :html => {:class => 'button-positive icon icon-add'},
              :param => :project_id,
              :caption => :title_easy_contact_type_new,
              :if => Proc.new { |p| User.current.allowed_to_manage_easy_contacts? }
  end

  Redmine::AccessControl.map do |map|
    map.project_module :easy_contacts do |pmap|
      pmap.permission :view_easy_contacts, {
          :easy_contacts => [:index, :show, :assign_entities, :remove_from_entity, :overview, :render_tab, :assign_to_partner],
          :journals => [:diff]
      }, global: true
      pmap.permission :manage_easy_contacts, {
          :easy_contacts => [:edit, :new, :update, :create, :change_avatar, :add_custom_field, :layout, :bulk_edit, :bulk_update, :update_bulk_form, :merge, :reg_no_query, :toggle_author_note],
          :my => [:create_contact_from_module]
      }, global: true
      pmap.permission :manage_author_easy_contacts, {
          :easy_contacts => [:edit, :new, :update, :create, :change_avatar, :add_custom_field, :layout, :bulk_edit, :bulk_update, :update_bulk_form, :merge, :reg_no_query, :toggle_author_note],
          :my => [:create_contact_from_module]
      }, global: true
      pmap.permission :manage_assigned_easy_contacts, {
          :easy_contacts => [:edit, :new, :update, :create, :change_avatar, :add_custom_field, :layout, :bulk_edit, :bulk_update, :update_bulk_form, :merge, :reg_no_query, :toggle_author_note],
          :my => [:create_contact_from_module]
      }, global: true
      pmap.permission :delete_easy_contacts, {:easy_contacts => [:destroy, :destroy_items]}, global: true
      pmap.permission :delete_author_easy_contacts, {:easy_contacts => [:destroy, :destroy_items]}, global: true
      pmap.permission :delete_assigned_easy_contacts, {:easy_contacts => [:destroy, :destroy_items]}, global: true
      pmap.permission :anonymize_easy_contacts, {:easy_contacts => [:anonymize, :bulk_anonymize]}, global: true
      pmap.permission :manage_easy_contact_groups, {:easy_contact_groups => [:index, :show, :edit, :new, :update, :create, :toggle_author_note]}, global: true
      pmap.permission :delete_easy_contact_groups, {:easy_contact_groups => [:destroy_items, :destroy]}, global: true
      pmap.permission :manage_easy_contact_types, {:easy_contact_types => [:index, :show, :new, :create, :edit, :update, :move_easy_contacts, :custom_field_mapping]}, global: true
      pmap.permission :delete_easy_contact_types, {:easy_contact_types => [:destroy, :show, :move_easy_contacts, :custom_field_mapping]}, global: true
      pmap.permission :add_note_easy_contacts, {:easy_contacts => :add_note}, global: true
      pmap.permission :add_note_easy_contact_groups, {:easy_contact_groups => :add_note}, global: true
      pmap.permission :assign_easy_contacts, {:easy_contacts => [:send_contact_by_mail]}, global: true
    end
  end

end

RedmineExtensions::Reloader.to_prepare do
  Dir[File.dirname(__FILE__) + '/lib/easy_contacts/field_formats/*.rb'].each { |file| require_dependency file }
  Dir[File.dirname(__FILE__) + '/lib/easy_contacts/easy_xml_import/**/*.rb'].each { |file| require_dependency file }

  require_dependency 'easy_contacts/easy_contacts_custom_fields'

  CustomFieldsHelper::CUSTOM_FIELDS_TABS << {:name => EasyContactCustomField.name, :partial => 'custom_fields/index', :label => :label_easy_contact_plural}
  CustomFieldsHelper::CUSTOM_FIELDS_TABS << {:name => EasyContactGroupCustomField.name, :partial => 'custom_fields/index', :label => :label_easy_contact_group}

  if Redmine::Plugin.installed?(:easy_mail_campaigns)
    require_dependency 'easy_mail_campaign_easy_contact'
  end

  require_dependency 'easy_contacts/easy_lookups/easy_lookup_easy_contact'
  EasyExtensions::EasyLookups::EasyLookup.map do |easy_lookup|
    easy_lookup.register 'EasyContacts::EasyLookups::EasyLookupEasyContact'
  end

  EasySetting.map.boolean_keys(:easy_carddav_enabled)

  # Register contacts and groups query to Easy
  EasyQuery.map do |query|
    query.register 'EasyContactQuery'
    query.register 'EasyContactGroupQuery'
  end

  Redmine::Search.map do |search|
    search.register :easy_contacts
  end
  
  AdvancedImporter.config.available_import_entities << 'EasyEntityImports::EasyContactCsvImport'
end
