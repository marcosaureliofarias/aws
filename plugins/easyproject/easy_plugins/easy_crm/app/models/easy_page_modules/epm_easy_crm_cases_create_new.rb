class EpmEasyCrmCasesCreateNew < EpmEntityCreateNew

  def category_name
    @category_name ||= 'easy_crm'
  end

  def runtime_permissions(user)
    user.allowed_to_globally?(:edit_easy_crm_cases, {}) || user.allowed_to_globally?(:edit_own_easy_crm_cases, {})
  end

  def entity
    EasyCrmCase
  end

  def get_show_data(settings, user, page_context = {})
    shown_fields = []
    shown_custom_field_ids = []
    settings['show_fields_option'] ||= 'all'
    fields = (settings['selected_fields'] ||= {})

    unless (easy_crm_case = page_context[:easy_crm_case])
      easy_crm_case = entity.new
      easy_crm_case.author = user
      easy_crm_case.easy_crm_case_status = EasyCrmCaseStatus.default || EasyCrmCaseStatus.all.first
      easy_crm_case_default_values_from_settings(easy_crm_case, fields, settings)
    end

    if settings['show_fields_option'] == 'only_selected'
      shown_fields = Array(settings['selected_fields']).select{|f| f[1].is_a?(Hash) && f[1]['enabled']}.collect{|f| f[0].to_sym}

      cf_ids = fields.keys & visible_entity_custom_field_values.map{|cfv| cfv.custom_field.id.to_s}
      cf_ids.each do |cf_id|
        shown_custom_field_ids << cf_id if fields[cf_id]['enabled']
      end
    elsif settings['show_fields_option'] == 'only_required'
      shown_fields = easy_crm_case.required_attribute_names | required_entity_fields
      shown_custom_field_ids = required_entity_custom_field_ids
    end

    { easy_crm_case: easy_crm_case, settings: settings, user: user, shown_custom_field_ids: shown_custom_field_ids,
      shown_fields: shown_fields, only_selected: settings['show_fields_option'] == 'only_selected',
      custom_field_values: settings['selected_fields']['custom_field_values'] }
  end

  def available_fields
    fields = {
        name: {},
        main_easy_contact_id: {label: :label_easy_crm_case_customer},
        project_id: {label: :field_project},
        easy_crm_case_status_id: {label: :label_easy_crm_case_status, values: EasyCrmCaseStatus.all, include_blank: false},
        assigned_to_id: {label: :"activerecord.attributes.easy_crm_case.account_manager"},
        external_assigned_to_id: {label: :"activerecord.attributes.easy_crm_case.external_account_manager"},
        contract_date: {label: :field_easy_crm_case_contract_date},
        next_action: {label: :field_easy_crm_case_next_action},
        email: {label: :field_mail},
        email_cc: {},
        telephone: {label: 'activerecord.attributes.easy_crm_case.telephone'},
        description: {},
        attachments: {},
        watcher: {},
        send_to_external_mails: {label: 'activerecord.attributes.easy_crm_case.send_to_external_mails'},
        price: {}
    }

    EasyCurrency.activated.any? ? fields.merge(currency: {}) : fields
  end

  def easy_crm_case_default_values_from_settings(easy_crm_case, fields, settings)
    return if fields.blank? || settings['show_fields_option'] != 'only_selected'

    assigned_to_id = fields['assigned_to_id']
    external_assigned_to_id = fields['external_assigned_to_id']

    fields.except('assigned_to_id', 'external_assigned_to_id').each do |name, options|
      easy_crm_case.send("#{name}=", options['default_value']) if options['default_value'].present?
    end

    assignable_user_ids = easy_crm_case.assignable_users.collect(&:id)
    if assigned_to_id && assigned_to_id['default_value'].present? && assignable_user_ids.include?(assigned_to_id['default_value'].to_i)
      easy_crm_case.assigned_to_id = assigned_to_id['default_value']
    end
    if external_assigned_to_id && external_assigned_to_id['default_value'].present? && assignable_user_ids.include?(external_assigned_to_id['default_value'].to_i)
      easy_crm_case.external_assigned_to_id = external_assigned_to_id['default_value']
    end
  end

end
