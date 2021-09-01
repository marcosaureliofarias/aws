module EasyContactGroupsHelper

  def parent_group_select_tag(group)
    selected = group.parent
    parent_id = (params[:easy_contact_group] && params[:easy_contact_group][:parent_id]) || params[:parent_id]
    if parent_id
      selected = (parent_id.blank? ? nil : EasyContactGroup.find(parent_id))
    end
    
    options = ''
    options << "<option value=''></option>" if group.allowed_parents.include?(nil)
    options << entity_tree_options_for_select(group.allowed_parents.compact, :selected => selected) do |e|
      { }
    end
    content_tag('select', options, :name => 'easy_contact_group[parent_id]')
  end

  def contacts_hide_elements(basic_id,group,project= nil)
    parent = basic_id + 'project-' + group.id.to_s
    root = project ? parent : basic_id + 'project-' + group.root.id.to_s
    return 'style="display:none"' if !toggle_button_expanded?(parent,nil) || !toggle_button_expanded?(root,nil)
  end

end
