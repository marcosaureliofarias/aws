module EasyContactsHelper

  VCARD_TO_EASY_CONTACT_MAPPINGS = {
      'EMAIL' => 'cf_email_value',
      'TEL' => 'cf_telephone_value',
      'ORG' => 'cf_organization_value',
      'ADR' => lambda { |c, val| _, _, c.cf_street_value, c.cf_city_value, _, c.cf_postal_code_value, _ = *val.split(';') },
      'N' => lambda { |c, val| c.lastname, c.firstname, _, c.cf_title_value = *val.split(';') }
  }

  def render_easy_contact_query_form_buttons_bottom_on_list(query, options)
    links = []

    EasyContactType.sorted.each do |type|
      links << content_tag(:li,
        link_to(type.name, { set_filter: 1, type_id: type.id }, class: type.css_icon)
      )
    end

    content_tag(:div, content_tag(:ul, links.join.html_safe), id: 'easy_contacts_quick_filter_buttons', class: 'tabs')
  end

  def contact_group_select_tag(contact)
    selected = contact.group_ids

    group_id = (params[:easy_contacts_group_assignment] && params[:easy_contacts_group_assignment][:group_id]) || params[:group_id]
    if group_id
      selected = (group_id.blank? ? nil : EasyContactGroup.find(group_id))
    end

    options = ''
    options << "<option value=''></option>" if contact.allowed_groups.include?(nil)
    options << entity_tree_options_for_select(contact.allowed_groups.compact, :selected => selected) do |e|
      {}
    end

    #    content_tag('select', options, { :name => 'easy_contacts_group_assignment[group_id][]', :multiple=>true })
    content_tag('select', options, {:name => 'easy_contact[group_ids][]', :multiple => true})
  end

  def render_contact_groups_tree(groups, options={})
    s = ''
    if groups.any?
      ancestors = []
      groups.sort_by(&:lft).each do |group|
        if ancestors.empty?
          s << "<ul class='sortable-tree'"
          s << " id='#{options[:id]}'" if options.key?(:id)
          s << ">\n"
        elsif group.is_descendant_of?(ancestors.last)
          s << "<ul>\n"
        else
          ancestors.pop
          s << "</li>"
          while (ancestors.any? && !group.is_descendant_of?(ancestors.last))
            ancestors.pop
            s << "</ul></li>\n"
          end
        end
        s << "<li"
        s << " id='#{options[:id]}-#{group.id}'" if options.key?(:id)
        s << "><span class='handle'></span><a class='easy-contact-group-node'>#{group.group_name}</a>\n"
        ancestors << group
      end
      s << ("</li></ul>\n" * ancestors.size)
    end
    s
  end

  def render_group_contacts_tree(group, options={})
    s = ''
    s << "<ul class='sortable-tree'"
    s << " id='#{options[:id]}'" if options.key?(:id)
    s << ">\n"

    #    group.contacts.each do |contact|
    #      s << "<li class='file'"
    #      s << " id='#{options[:id]}-#{contact.id}'" if options.key?(:id)
    #      s << "><a class='easy-contact-node'>#{contact.contact_name}</a></li>\n"
    #    end unless group.nil?
    group.contacts.each do |contact|
      s << "<li class='node-contact'"
      s << " id='#{options[:id]}-#{contact.id}'" if options.key?(:id)
      s << "><a class='easy-contact-node'>"
      s << image_tag(contact.easy_contact_type.icon_path)
      s << "#{contact.contact_name}</a></li>\n"
    end unless group.nil?
    s << "</ul>"
    s
  end

  def easy_contact_tabs(easy_contact)
    tabs = []
    tabs << { name: 'history', label: l(:label_history), trigger: 'EntityTabs.showHistory(this)', partial: 'easy_contacts/tabs/history' }
    url = render_tab_easy_contact_path(easy_contact, tab: 'easy_entity_activity')
    tabs << { name: 'easy-entity-activity', label: l(:label_easy_entity_activity), trigger: "EntityTabs.showAjaxTab(this, '#{url}')" }

    call_hook(:helper_easy_contact_tabs, tabs: tabs, easy_contact: easy_contact)
    tabs
  end

  def index_get_inputs
    return '$("form .entities .easy-contact input[type=checkbox]")'
  end

  def easy_contacts_send_mail_link
    easy_modal_selector_link_with_submit('EasyContactForMail', 'mail', 'recipients', 'ids_for_mail', index_get_inputs, :form_url => {:controller => 'easy_contacts', :action => 'send_contact_by_mail', :modal_project_id => @project}, :trigger_options => {:name => l('easy_contact_action.send_mail'), :html => {:title => l('easy_contact_action.send_mail')}})
  end

  def easy_contacts_assign_contacts_to_projects_link
    easy_modal_selector_link_with_submit('EasyContactForProject', 'name', 'entity_ids', 'ids_for_assign_project', index_get_inputs, :form_url => {:controller => 'easy_contacts', :action => 'assign_entities', :modal_project_id => @project, :entity_type => 'Project', :back_url => easy_contacts_path(:project_id => @project)}, :trigger_options => {:name => l('easy_contact_action.add_to_project'), :html => {:title => l('easy_contact_action.add_to_project'), :id => 'some'}})
  end

  #  def easy_contacts_assign_contacts_to_users_link
  #    easy_modal_selector_link_with_submit('EasyContactGroupForUser', 'group_name', 'group_ids', 'ids_for_assign_user', index_get_inputs, :form_url => {:controller => 'easy_contacts', :action => 'assign_groups'}, :trigger_options => {:name => l('easy_contact_action.add_to_user'), :html => {:title => l('easy_contact_action.add_to_user')}})
  #  end

  def easy_contacts_assign_contacts_to_group_link
    easy_modal_selector_link_with_submit('EasyContactGroup', 'group_name', 'entity_ids', 'ids_for_assign_group', index_get_inputs, :form_url => {:controller => 'easy_contacts', :action => 'assign_entities', :modal_project_id => @project, :entity_type => 'EasyContactGroup', :back_url => easy_contacts_path(:project_id => @project)}, :trigger_options => {:name => l('easy_contact_action.add_to_group'), :html => {:title => l('easy_contact_action.add_to_group')}}, :url => {:project_id => @project})
  end


  def easy_contact_send_mail_link
    easy_modal_selector_link_with_submit('EasyContactForMail', 'mail', 'recipients', 'ids_for_mail', '$(\'#entity_id\')', :form_url => {:controller => 'easy_contacts', :action => 'send_contact_by_mail', :modal_project_id => @project}, :trigger_options => {:name => l('easy_contact_action.send_mail'), :html => {:title => l('easy_contact_action.send_mail'), :class => 'icon icon-mail'}})
  end

  # for index page
  def easy_contacts_reference_link(html_options={})
    easy_modal_selector_link_with_submit('EasyContact', 'contact_name', 'entity_ids', 'ids_for_assign_contact', index_get_inputs, :form_url => {:controller => 'easy_contacts', :action => 'assign_entities', :modal_project_id => @project, :entity_type => 'EasyContact', :back_url => easy_contacts_path(:project_id => @project)}, :trigger_options => {:name => l('easy_contact_action.add_to_contact'), :html => html_options.merge({:title => l('easy_contact_action.add_to_contact')})})
  end

  # for show page
  def easy_contact_reference_link(selected_values = {})
    easy_modal_selector_link_with_submit('EasyContact', 'contact_name', 'entity_ids', 'ids_for_assign_contact', '$("#entity_id")', :selected_values => selected_values, :form_url => {:controller => 'easy_contacts', :action => 'assign_entities', :modal_project_id => @project, :entity_type => 'EasyContact'}, :trigger_options => {:name => l('easy_contact_action.add_to_contact'), :html => {:title => l('easy_contact_action.add_to_contact'), :class => 'icon icon-relation'}})
  end

  def easy_contacts_assign_contact_to_projects_link
    easy_modal_selector_link_with_submit('EasyContactForProject', 'name', 'entity_ids', 'ids_for_assign_project', '$("#entity_id")', :form_url => {:controller => 'easy_contacts', :action => 'assign_entities', :modal_project_id => @project, :entity_type => 'Project'}, :trigger_options => {:name => l('easy_contact_action.add_to_project'), :html => {:title => l('easy_contact_action.add_to_project'), :class => 'icon icon-add', :id => 'some'}})
  end

  #  def easy_contacts_assign_contact_to_users_link(entity = nil)
  #    easy_modal_selector_link_with_submit('EasyContactGroupForUser', 'group_name', 'group_ids','ids_for_assign_user', '[$(\'entity-id\')]', :form_url => {:controller => 'easy_contacts', :action => 'assign_groups'}, :trigger_options => {:name => l('easy_contact_action.add_to_user'), :html => {:title => l('easy_contact_action.add_to_user')}})
  #  end

  def easy_contacts_assign_contact_to_group_link(contact_id)
    easy_modal_selector_link_with_submit('EasyContactGroup', 'group_name', 'entity_ids', 'ids_for_assign_global', '$("#entity_id")', :form_url => {:controller => 'easy_contacts', :action => 'assign_entities', :id => contact_id, :entity_type => 'EasyContactGroup'}, :trigger_options => {:name => l('easy_contact_action.add_to_group'), :html => {:title => l('easy_contact_action.add_to_group'), :class => 'icon icon-group'}})
  end

  def vcard_import(easy_contact, vcf)
    return nil if vcf.value('N').nil? or vcf.value('N').fullname.empty?

    easy_contact.init_journal(User.current)

    contents = vcf.fields.select { |f| !(%w(BEGIN VERSION UID END).include? f.name) }

    contents.each do |c|
      if mapped_to = VCARD_TO_EASY_CONTACT_MAPPINGS[c.name]
        if mapped_to.respond_to? :call
          mapped_to.call easy_contact, c.value
        else
          easy_contact.send "#{mapped_to}=", c.value
        end
      end
    end

    easy_contact.save
  end

  def vcard_export(easy_contacts, options={})
    require 'vcard'
    vcards = Array.new
    mappings_fields = CustomFieldMapping.where(:format_type => 'vcard').to_a.group_by(&:name)
    allow_avatar = options.key?(:allow_avatar) ? options[:allow_avatar] : true
    Array(easy_contacts).each do |easy_contact|

      vcards << Vcard::Vcard::Maker.make2 do |maker|

        # location = easy_contact.person? ? 'home' : 'work'
        location = 'work'

        maker.add_name do |name|
          if mappings_fields['prefix'] && val = easy_contact.custom_field_value(mappings_fields['prefix'].first.custom_field_id)
            name.prefix = val.to_s
          end
          name.given = easy_contact.firstname.to_s
          name.family = easy_contact.lastname.to_s
        end

        if val = easy_contact.custom_field_value(mappings_fields['org'].first.custom_field_id)
          maker.org = val
        end

        if val = easy_contact.custom_field_value(mappings_fields['street'].first.custom_field_id)
          addr_street = val
        end
        if val = easy_contact.custom_field_value(mappings_fields['postalcode'].first.custom_field_id)
          addr_postalcode = val
        end
        if val = easy_contact.custom_field_value(mappings_fields['locality'].first.custom_field_id)
          addr_locality = val
        end
        if val = easy_contact.custom_field_value(mappings_fields['country'].first.custom_field_id)
          addr_country = val
        end

        if addr_street.present? || addr_postalcode.present? || addr_locality.present? || addr_country.present?
          maker.add_addr do |addr|
            addr.preferred = true
            addr.location = location
            addr.street = addr_street || ''
            addr.postalcode = addr_postalcode || ''
            addr.locality = addr_locality || ''
            addr.country = addr_country || ''
          end
        end

        if val = easy_contact.custom_field_value(mappings_fields['add_tel'].first.custom_field_id)
          maker.add_tel(val) do |tel|
            tel.preferred = true
            tel.location = location
            tel.capability = 'voice'
          end unless val.blank?
        end

        if val = easy_contact.custom_field_value(mappings_fields['add_email'].first.custom_field_id)
          maker.add_email(val) do |mail|
            mail.preferred = true
            mail.location = location
          end unless val.blank?
        end

        if allow_avatar && avatar = easy_contact.easy_avatar
          img = avatar.image
          img_path = img.path(:medium)
          if File.exists?(img_path)
            maker.add_photo do |photo|
              photo.image = File.read(img_path)
              photo.type = img.content_type.split('/').last.upcase
            end
          end
        end

        maker.add_field Vcard::DirectoryInfo::Field.create('UID', easy_contact.guid)
        maker.add_field Vcard::DirectoryInfo::Field.create('REV', easy_contact.updated_on.iso8601)
      end
    end

    return vcards
  end

  def contact_label_headers_for_import
    headers = []
    headers << label_for_field(:firstname, :required => true)
    headers << label_for_field(:lastname)
    custom_field_value = CustomFieldValue.new

    EasyContacts::CustomFields.contact_field_ids.each do |cf_id|
      next unless custom_field_value.custom_field = CustomField.find_by_id(cf_id)
      headers << custom_field_label_tag('easy_contact', custom_field_value)
    end

    headers
  end
  def render_contacts_ancestors_tree(contacts)
    s = '<form action=""><table class="list contacts ancestors">'
    issue_list(contacts) do |child, level|
      contacts_tree_contain(s, child, level)
    end
    s << '</table></form>'
    s << context_menu(context_menus_easy_contacts_path, 'table.list.contacts.ancestors')
    s.html_safe
  end

  def render_contacts_descendants_tree(contacts)
    s = '<form action=""><table class="list contacts descendants">'
    issue_list(contacts) do |child, level|
      contacts_tree_contain(s, child, level)
    end
    s << '</table></form>'
    s << context_menu(context_menus_easy_contacts_path, 'table.list.contacts.descendants')
    s.html_safe
  end

  def contacts_tree_contain(s, child, level)
    sorted_custom_values = child.visible_custom_field_values.first(EasyContactCustomField::CONTACTS_TREE_CF_COUNT)
    s << "<tr class='#{child.css_classes} contact-#{child.id} hascontextmenu #{level > 0 ? "idnt idnt-#{level}" : nil}' onclick='EASY.utils.goToUrl(\"#{easy_contact_path(child)}\", event)'>"
    s << content_tag('td', check_box_tag("ids[]", child.id, false, id: nil), class: 'checkbox hide-when-print')
    s << content_tag('td', link_to(child.name, easy_contact_path(child)), class: 'name')
    s << content_tag('td', child.type, class: 'contact-type', colspan: EasyContactCustomField::CONTACTS_TREE_CF_COUNT + 1 - sorted_custom_values.count)
    sorted_custom_values.each do |custom_value|
      s << content_tag('td', show_value(custom_value))
    end if sorted_custom_values.present?
    s << content_tag('td', easy_contact_query_additional_ending_buttons(child), class: 'easy-query-additional-ending-buttons hide-when-print')
    s << '</tr>'
  end

end
