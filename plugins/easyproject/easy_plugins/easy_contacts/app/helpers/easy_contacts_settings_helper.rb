module EasyContactsSettingsHelper

  def easy_contacts_tabs
    tabs = [{:name => 'EasyContactType', :partial => 'easy_contact_types/index', :label => l('administration.label_easy_contact_type')},
      {:name => 'EasyContactFieldsSettings', :partial => 'easy_contacts_settings/fields_settings', :label => l(:label_easy_contact_fields_settings)},
      #{:name => 'EasyContactGroupCustomField', :partial => 'custom_fields/easy_contact_group_index', :label => l('administration.label_easy_contact_group' )},
     # {:name => 'EasyContactCustomField', :partial => 'custom_fields/easy_contact_index', :label => l('administration.label_easy_contact' )}
    ]
  end
  
end
