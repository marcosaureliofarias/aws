class EpmEasyContactsCreateNew < EpmEntityCreateNew

  def category_name
    @category_name ||= 'contacts'
  end

  def runtime_permissions(user)
    user.allowed_to_globally?(:manage_easy_contacts, {}) ||
    user.allowed_to_globally?(:manage_author_easy_contacts, {}) ||
    user.allowed_to_globally?(:manage_assigned_easy_contacts, {})
  end

  def entity
    EasyContact
  end

  def get_show_data(settings, user, page_context = {})
    shown_fields = []
    shown_custom_field_ids = []
    settings['show_fields_option'] ||= 'all'
    fields = (settings['selected_fields'] ||= {})

    unless (easy_contact = page_context[:easy_contact])
      easy_contact = entity.new
      easy_contact.easy_contact_type = EasyContactType.default
      easy_contact.author = user
      easy_contact_default_values_from_settings(easy_contact, fields, settings)
    end

    if settings['show_fields_option'] == 'only_selected'
      shown_fields = Array(settings['selected_fields']).select{|f| f[1].is_a?(Hash) && f[1]['enabled']}.collect{|f| f[0].to_sym}

      cf_ids = fields.keys & visible_entity_custom_field_values.map{|cfv| cfv.custom_field.id.to_s}
      cf_ids.each do |cf_id|
        shown_custom_field_ids << cf_id if fields[cf_id]['enabled']
      end
    elsif settings['show_fields_option'] == 'only_required'
      shown_fields = required_entity_fields << :type_id
      shown_custom_field_ids = required_entity_custom_field_ids
    end

    { easy_contact: easy_contact, settings: settings, user: user, shown_custom_field_ids: shown_custom_field_ids,
      shown_fields: shown_fields, only_selected: settings['show_fields_option'] == 'only_selected',
      custom_field_values: settings['selected_fields']['custom_field_values'] }
  end

  def available_fields
    {
        type_id: {label: 'administration.label_easy_contact_type', values: EasyContactType.sorted},
        firstname: {},
        lastname: {},
        assigned_to_id: {label: :"activerecord.attributes.easy_contacts.account_manager"},
        external_assigned_to_id: {label: :"activerecord.attributes.easy_contacts.external_account_manager"},
        parent_id: {label: :field_easy_contact_parent},
        private: {label: :field_easy_contact_private},
        is_global: {label: :field_is_global},
        assign_to_me: {label: :label_assign_to_me},
        easy_contact_references: {label: :label_easy_contact_references, entity_type: 'EasyContact'},
        easy_contact_group_ids: {label: :label_easy_contact_references_groups, entity_type: 'EasyContactGroup'},
        description: {},
        attachments: {}
    }
  end

  private

  def easy_contact_default_values_from_settings(easy_contact, fields, settings)
    return if fields.blank? || settings['show_fields_option'] != 'only_selected'

    special_fields = ['easy_contact_references', 'description']

    fields.each do |name, options|
      if special_fields.include?(name)
        case name
        when 'description'
          easy_contact.author_note = options['default_value'] if options['default_value'].present?
        when 'easy_contact_references'
          easy_contact.references_by = EasyContact.where(id: options['default_value']) if options['default_value'].present?
        end
      else
        easy_contact.send("#{name}=", options['default_value']) if options['default_value'].present?
      end
    end
  end

end
