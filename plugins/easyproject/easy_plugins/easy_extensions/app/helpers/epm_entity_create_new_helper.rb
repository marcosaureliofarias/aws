module EpmEntityCreateNewHelper

  def get_entity_field_attribute(entity_name, field_name, options = {})
    @field_name     = field_name
    @field_val_name = options[:field_val_name]
    @field_settings = options[:field_settings]
    @field_val_id   = options[:field_val_id]
    @block_name     = options[:block_name]
    @value          = options[:value]

    send("get_#{entity_name}_field_attribute")
  end

  def get_issue_field_attribute
    case @field_name
    when :subject
      text_field_tag @field_val_name, @value, size: 60
    when :description
      text_area_tag @field_val_name, @value, cols: 60, rows: 10
    when :project_id
      selected_project_value = @value.blank? ? { name: '', id: '' } : { name: Project.where(id: @value).pluck(:name).join, id: @value }
      easy_select_tag(@field_val_name,
                      selected_project_value,
                      @field_settings[:values].blank? ? nil : project_tree_options_for_select(@field_settings[:values], selected: @value),
                      easy_autocomplete_path('add_issue_projects'),
                      html_options: { id: @field_val_id },
                      root_element: 'projects')
    when :tracker_id
      select_tag @field_val_name, options_for_select(@field_settings[:values].collect { |t| [t.name, t.id.to_s] }, @value), { include_blank: true, multiple: true, size: 6 }
    when :assigned_to_id, :priority_id, :status_id, :fixed_version_id
      select_tag @field_val_name, options_for_select(@field_settings[:values].collect { |t| [t.name, t.id.to_s] }, @value), { include_blank: true }
    when :start_date, :due_date
      result = text_field_tag @field_val_name, @value, size: 10, id: "#{@block_name}-#{@field_name}"
      result << calendar_for("#{@block_name}-#{@field_name}")
      result.html_safe
    when :attachments, :easy_is_repeating, :easy_issue_timer, :parent_issue_id
      hidden_field_tag @field_val_name, @value
    when :category
      hidden_field_tag @field_val_name, ''
    when :estimated_hours
      text_field_tag @field_val_name, @value, size: 3, placeholder: l(:field_hours)
    when :watchers
      easy_multiselect_tag "#{@field_val_name}[]", @field_settings[:values].collect { |t| [t.name, t.id.to_s] }, Array.wrap(@value), select_first_value: false, html_options: { include_blank: true }
    else
      text_field_tag @field_val_name, @value
    end
  end

  def get_easy_contact_field_attribute
    case @field_name
    when :firstname, :lastname
      text_field_tag @field_val_name, @value
    when :description
      text_area_tag @field_val_name, @value
    when :private, :is_global, :assign_to_me
      check_box_tag @field_val_name, '1', @value.to_boolean
    when :parent_id
      parent = EasyContact.find_by(id: @value)
      easy_autocomplete_tag(@field_val_name,
                            parent ? { name: parent.name, id: parent.id } : { name: '' },
                            easy_autocomplete_path('easy_contacts_visible_contacts'),
                            html_options: { id: "#{@block_name}_parent_id" },
                            root_element: 'easy_contacts')
    when :assigned_to_id
      user = User.find_by(id: @value)
      easy_autocomplete_tag(@field_val_name,
                            user ? { name: user.name, id: user.id } : { name: '' },
                            easy_autocomplete_path('assignable_principals_easy_contact'),
                            html_options: { id: "#{@block_name}_assigned_to_id" },
                            preload: false,
                            root_element: 'users',
                            force_autocomplete: true,
                                    easy_autocomplete_options: {
                                        activate_on_input_click: true,
                                        widget: 'catcomplete',
                                        delay: 50,
                                        minLength: 0
                                    })
    when :external_assigned_to_id
      user = User.find_by(id: @value)
      easy_autocomplete_tag(@field_val_name,
                            user ? { name: user.name, id: user.id } : { name: '' },
                            easy_autocomplete_path('assignable_principals_easy_contact', external: true),
                            html_options: { id: "#{@block_name}_external_assigned_to_id" },
                            preload: false,
                            root_element: 'users',
                            force_autocomplete: true,
                                    easy_autocomplete_options: {
                                        activate_on_input_click: true,
                                        widget: 'catcomplete',
                                        delay: 50,
                                        minLength: 0
                                    })
    when :type_id
      select_tag @field_val_name, options_for_select(@field_settings[:values].collect { |t| [t.name, t.id.to_s] }, @value)
    when :easy_contact_references, :easy_contact_group_ids
      selected_entities = @field_settings[:entity_type].constantize.where(id: @value)
      easy_modal_selector_field_tag(@field_settings[:entity_type], 'link_with_name', @field_val_name, @field_val_name,
                                    EasyExtensions::FieldFormats::EasyLookup.entity_to_lookup_values(selected_entities),
                                    hide_create_contact: true, class: 'block')
    when :attachments
      # Without default value
    else
      text_field_tag @field_val_name, @value
    end
  end

  def get_easy_crm_case_field_attribute
    case @field_name
    when :name, :price, :email, :email_cc, :telephone
      text_field_tag @field_val_name, @value
    when :description
      text_area_tag @field_val_name, @value, cols: 60, rows: 10
    when :currency
      select_tag :currency, options_from_collection_for_select(EasyCurrency.activated, :iso_code, :name, @value), { class: 'inline' }
    when :main_easy_contact_id
      easy_contact = EasyContact.find_by(id: @value)
      easy_autocomplete_tag(@field_val_name,
                            easy_contact ? { name: easy_contact.name, id: easy_contact.id } : { name: '' },
                            easy_autocomplete_path('easy_contacts_visible_contacts'),
                            html_options: { id: "#{@block_name}_main_easy_contact_id" },
                            root_element: 'easy_contacts')
    when :project_id
      project = Project.find_by(id: @value)
      easy_select_tag(@field_val_name,
                      project ? { name: project.name, id: project.id } : { name: '' },
                      nil,
                      easy_autocomplete_path('easy_crm_projects'),
                      root_element: 'projects',
                      html_options: { id: "#{@block_name}_easy_crm_case_project_id" })
    when :easy_crm_case_status_id
      select_tag @field_val_name, options_for_select(@field_settings[:values].collect { |u| [u.name, u.id.to_s] }, @value), { include_blank: @field_settings[:include_blank] }
    when :assigned_to_id
      user = User.find_by(id: @value)
      easy_autocomplete_tag(@field_val_name,
                            user ? { name: user.name, id: user.id } : { name: '' },
                            easy_autocomplete_path('assignable_principals_easy_crm_case'),
                            html_options: { id: "#{@block_name}_assigned_to_id" },
                            preload: false,
                            root_element: 'users',
                            force_autocomplete: true,
                                    easy_autocomplete_options: {
                                        activate_on_input_click: true,
                                        widget: 'catcomplete',
                                        delay: 50,
                                        minLength: 0
                                    })
    when :external_assigned_to_id
      user = User.find_by(id: @value)
      easy_autocomplete_tag(@field_val_name,
                            user ? { name: user.name, id: user.id } : { name: '' },
                            easy_autocomplete_path('assignable_principals_easy_crm_case', external: true),
                            html_options: { id: "#{@block_name}_external_assigned_to_id" },
                            preload: false,
                            root_element: 'users',
                            force_autocomplete: true,
                                    easy_autocomplete_options: {
                                        activate_on_input_click: true,
                                        widget: 'catcomplete',
                                        delay: 50,
                                        minLength: 0
                                    })
    when :contract_date
      result = text_field_tag @field_val_name, @value, size: 10, id: "#{@block_name}-#{@field_name}"
      result << calendar_for("#{@block_name}-#{@field_name}")
      result.html_safe
    when :send_to_external_mails
      check_box_tag @field_val_name, '1', @value.to_boolean
    when :next_action, :attachments, :watcher
      # Without default value
    else
      text_field_tag @field_val_name, @value
    end
  end

end