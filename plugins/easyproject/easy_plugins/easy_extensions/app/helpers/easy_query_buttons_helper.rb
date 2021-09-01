module EasyQueryButtonsHelper
  # Returns a additional fast-icons buttons
  # - entity - instance of ...
  # - query - easy_query
  # - options - :no_link => true - no html links will be rendered
  #
  def easy_query_additional_beginning_buttons(query, entity, options = {})
    return ''.html_safe if query.nil? || entity.nil?
    easy_query_additional_buttons_method = "#{query.type.underscore}_additional_beginning_buttons".to_sym

    additional_buttons = ''
    if respond_to?(easy_query_additional_buttons_method)
      additional_buttons = send(easy_query_additional_buttons_method, entity, options)
    end

    return additional_buttons.html_safe
  end

  def easy_query_additional_ending_buttons(query, entity, options = {})
    return ''.html_safe if query.nil? || entity.nil?
    easy_query_additional_buttons_method = "#{query.type.underscore}_additional_ending_buttons".to_sym

    additional_buttons = ''
    if respond_to?(easy_query_additional_buttons_method)
      additional_buttons = send(easy_query_additional_buttons_method, entity, options)
    end

    options[:source_entity] ||= query.options[:source_entity] if query.respond_to?(:options)
    if options[:source_entity].present? && (entity.respond_to?(:editable?) ? entity.editable? : true) && !options[:hide_remove_entity_link]
      additional_buttons << link_to(content_tag(:span, l(:title_remove_referenced_entity_from_entity,
                                                         source_entity: options[:source_entity].to_s),
                                                class: 'tooltip'),
                                    { controller:                 'easy_entity_assignments', action: 'destroy',
                                      source_entity_type:         options[:source_entity].class,
                                      source_entity_id:           options[:source_entity].id,
                                      referenced_entity_type:     entity.class,
                                      referenced_entity_id:       entity.id,
                                      referenced_collection_name: options[:referenced_collection_name],
                                      display_style:              options[:display_style] },
                                    method: :delete, remote: true, class: 'icon icon-unlink',
                                    data:   { confirm: l(:text_are_you_sure) })
    end
    return additional_buttons.html_safe
  end

  def easy_easy_query_query_additional_ending_buttons(entity, options = {})
    s = ''
    s << link_to('', edit_easy_query_path(entity, back_url: edit_easy_query_management_path(type: entity.type)), :class => 'icon icon-edit', :title => l(:title_edit_projectquery))
    s << link_to('', easy_query_path(entity, back_url: edit_easy_query_management_path(type: entity.type)), :data => { :confirm => l(:text_are_you_sure) }, :method => 'delete', :class => 'icon icon-del', :title => l(:title_delete_projectquery))
    s.html_safe
  end

  def easy_time_entry_query_additional_ending_buttons(time_entry, options = {})
    s = ''
    if time_entry.editable_by?(User.current)
      s << link_to('', edit_easy_time_entry_path(time_entry), :title => l(:button_edit), :class => 'icon icon-edit')
      s << link_to('', easy_time_entry_path(time_entry, :project_id => nil),
                   :data   => { :confirm => l(:text_are_you_sure) },
                   :method => :delete,
                   :title  => l(:button_delete),
                   :class  => 'icon icon-del') unless time_entry.easy_attendance
    end
    return s.html_safe
  end

  def easy_attendance_query_additional_ending_buttons(entity, options = {})
    s = ''

    if User.current.allowed_to_globally?(:use_easy_attendances)
      s << link_to('', '#', :class => 'icon icon-more-horiz btn_contextmenu_trigger', title: l(:title_additional_context_menu))
      s << link_to('', edit_easy_attendance_path(entity, { :tab => params[:tab], :back_url => back_url }), :class => 'icon icon-edit', title: l(:button_edit)) if entity.can_edit?
      s << link_to('', easy_attendance_path(entity, { :tab => params[:tab], :back_url => back_url }), :method => :delete, :data => { :confirm => l(:text_are_you_sure) }, :class => 'icon icon-del', title: l(:button_delete)) if entity.can_delete?
    end

    s.html_safe
  end

  def easy_page_query_additional_ending_buttons(entity, options = {})
    s = ''

    if entity.is_user_defined?
      s << link_to(l(:button_edit), edit_easy_page_path(entity), class: 'icon icon-edit', title: l(:button_edit))
      s << link_to(l(:button_delete), easy_page_path(entity),
                   method: :delete,
                   data:   { confirm: l(:text_are_you_sure) },
                   class:  'icon icon-del',
                   title:  l(:button_delete))
      if User.current.easy_lesser_admin_for?(:easy_xml_data_import) && Redmine::Plugin.installed?(:easy_data_templates)
        s << link_to(l(:button_export), easy_xml_easy_pages_export_path(format: :xml, id: entity.id),
                     title:  l(:button_export),
                     method: :post,
                     class:  'icon icon-export')
      end
    elsif entity.has_template?
      s << link_to(l(:button_easy_page_templates), easy_page_templates_path(page_id: entity.id),
                   title: l(:title_easy_page_templates),
                   class: 'button-positive')
    end

    s.html_safe
  end

  def easy_version_query_additional_ending_buttons(version, options = {})
    s = ''
    s << link_to(l(:button_edit),
                 edit_version_path(version, project_id: @project),
                 class: 'icon icon-edit',
                 title: l(:button_edit))
    if User.current.allowed_to?(:manage_versions, @project, global: true)
      s << delete_link(versions_bulk_destroy_path(ids: version, project_id: @project))
    end
    s.html_safe
  end

  def easy_entity_import_query_additional_ending_buttons(entity, options = {})
    html = ''
    unless entity.class.disabled?
      html.concat(link_to(l(:button_show), easy_entity_import_path(entity), :class => 'icon icon-magnifier'))
      html.concat(link_to(l(:button_edit), edit_easy_entity_import_path(entity), :class => 'icon icon-edit'))
      html.concat(link_to(l(:button_delete), easy_entity_import_path(entity), :class => 'icon icon-del', :method => 'delete'))
    end

    html.html_safe
  end

  def easy_issue_query_additional_ending_buttons(issue, options = {})
    page_module = options[:page_module].presence
    case page_module
    when EasyPageZoneModule
      buttons = page_module.settings['easy_query_end_buttons']
    when String
      # If group is opened on page module
      @zone_module_settings ||= {}
      if @zone_module_settings.key?(page_module)
        setting = @zone_module_settings[page_module]
      else
        setting                            = EasyPageZoneModule.where(uuid: page_module).pluck(:settings).first
        @zone_module_settings[page_module] = setting
      end
      buttons = setting && setting['easy_query_end_buttons']
    end

    s = ''
    #s << '<span class="icon icon-settings"><span class="tooltip">'

    if page_module && (buttons.nil? || buttons.include?('favorite'))
      favorited       = @favorited_entity_ids.include?(issue.id) if @favorited_entity_ids
      favorited       ||= issue.favorited_by.any? { |favorite| favorite.id == User.current.id }
      favorited_label = favorited ? l(:label_unfavorite) : l(:label_favorite)

      s << link_to(content_tag(:span, favorited_label, class: 'tooltip'), favorite_issue_path(issue), remote: true, method: :post, class: "toggle-favorite #{favorited ? 'icon-fav favorited' : 'icon-fav-off'}", id: "favorite_issue_#{issue.id}", title: favorited_label)
    end

    s << issue_preview_link(issue, options) if !in_mobile_view? && (buttons.nil? || buttons.include?('preview'))
    s << link_to(content_tag(:span, l(:button_update), class: 'tooltip'), easy_edit_issue_path(issue), class: 'icon icon-edit', title: l(:button_update)) if buttons.nil? || buttons.include?('edit')

    # I'm on it is shown only if buttons include `iam_on_it`
    if buttons && buttons.include?('iam_on_it') &&
        EasyIssueTimer.active?(issue.project) && User.current.allowed_to?(:log_time, issue.project) && issue.editable?

      timer = issue.easy_issue_timers.where(user_id: User.current.id).running.last
      if timer && !timer.paused?
        s << link_to('', easy_issue_timer_stop_path(issue, timer_id: timer), class: 'icon-checked-circle', method: :post, title: l(:button_easy_issue_timer_stop))
      else
        title = l(timer.nil? ? :button_easy_issue_timer_play : :button_easy_issue_timer_resume)
        s << link_to('', easy_issue_timer_play_path(issue, timer_id: timer), class: 'icon-play', method: :post, title: title)
      end
    end

    #s << "</span></span>"
    return s.html_safe
  end

  def easy_issue_query_additional_beginning_buttons(issue, options = {})
    s = ''
    s << content_tag(:span, content_tag(:span, issue.to_s, :class => 'hidden'), :data => { :entity_type => 'Issue', :name => 'issue[subject]', :type => 'text', :entity_id => issue.id, :value => issue.to_s, :handler => true })
    s << '<span class="beginning-buttons-wrapper icon__stack">'

    if issue.unread?
      s << content_tag(:i, '', :class => 'icon icon-message red-icon unread', title: l(:label_unread_entity))
    else
      s << content_tag(:i, '', :class => 'icon icon-message opaque-icon', title: l(:label_unread_entity))
    end
    if issue.is_private? && EasySetting.value(:enable_private_issues)
      s << content_tag(:i, '', :class => 'icon icon-watcher red-icon private', title: l(:field_is_private))
    end

    call_hook(:helper_easy_issue_query_beginning_buttons, { :issue => issue, :content => s })
    s << '</span>'
    s.html_safe
  end

  def issue_preview_link(issue, options)
    link_to(content_tag(:span, l(:title_preview_link), class: 'tooltip'), issue_render_preview_path(issue, {block_name: options[:block_name], uniq_id: options[:uniq_id]}), id: "#{options[:block_name]}#{options[:uniq_id]}link-to-easy-issues-render-last-journal-#{issue.id}", remote: true, title: l(:title_preview_link), class: 'icon icon-preview')
  end

  def easy_change_status_link(user, options = {})
    url = { :controller => 'users', :action => 'update', :id => user, :page => params[:page], :status => params[:status], :tab => nil }

    if user.locked?
      link = link_to l(:button_unlock), url.merge(:user => { :status => User::STATUS_ACTIVE }), :method => :put, :class => "icon icon-unlock #{options[:additional_classes]}"
    elsif user.registered?
      link = link_to l(:button_activate), url.merge(:user => { :status => User::STATUS_ACTIVE }), :method => :put, :class => "icon icon-unlock #{options[:additional_classes]}"
    elsif user != User.current
      link = link_to l(:button_lock), url.merge(:user => { :status => User::STATUS_LOCKED }), :data => { :confirm => l(:text_are_you_sure) }, :method => :put, :class => "icon icon-lock #{options[:additional_classes]}"
    end

    if user.locked? &&
        ((user.internal_client? && !EasyLicenseManager.has_license_limit?(:internal_user_limit)) ||
            (user.external_client? && !EasyLicenseManager.has_license_limit?(:external_user_limit)))
      link = content_tag(:span, l('license_manager.user_limit_unlock_button'), :style => 'color: red')
    end
    link
  end

  def easy_entity_action_query_additional_ending_buttons(entity, options = {})
    s = ''

    if entity.editable?
      s << link_to(l(:button_edit), edit_easy_entity_action_path(entity), :class => 'icon icon-edit', :title => l(:button_edit))
      s << link_to(l(:button_delete), easy_entity_action_path(entity), :method => :delete, :data => { :confirm => l(:text_are_you_sure) }, :class => 'icon icon-del', :title => l(:button_delete))
    end

    s.html_safe
  end

  def easy_document_query_additional_ending_buttons(document, options = {})
    s = ''
    if params[:easy_printable_template_id].present?
      s << link_to(l(:button_save), save_to_document_easy_printable_template_path(params[:easy_printable_template_id].to_i, document_id: document.id, serializable_attributes: params.to_unsafe_hash['serializable_attributes']), method: :post, class: 'icon icon-save')
    else
      s << link_to(l(:button_show), document_path(document), title: l(:button_show)) if document.visible?
      s << link_to(l(:button_edit), edit_document_path(document), class: 'icon icon-edit', title: l(:button_edit)) if document.editable?
      s << delete_link(document_path(document), class: 'icon icon-del') if document.deletable?
    end
    s.html_safe
  end

  def easy_user_query_additional_ending_buttons(user, options = {})
    links = Array.new
    links << link_to('', { :controller => 'users', :action => 'show', :id => user }, :class => 'icon icon-user', :title => l(:button_view), :alt => l(:button_view))
    links << link_to('', '#', :class => 'icon icon-more-horiz btn_contextmenu_trigger', title: l(:title_additional_context_menu))

    return links.join.html_safe
  end

  def easy_project_query_additional_ending_buttons(project, options = {})
    favorited_label = project.favorited ? l(:label_unfavorite) : l(:label_favorite)
    link_to(content_tag(:span, favorited_label, class: 'tooltip'), favorite_project_path(project), remote: true, method: :post, class: "toggle-favorite #{project.favorited ? 'icon-fav favorited' : 'icon-fav-off'}", id: "favorite_project_#{project.id}", title: favorited_label, onclick: '$(this).parent().toggleClass("u__opacity--1")')
  end

  def easy_admin_project_query_additional_ending_buttons(project, options = {})
    s = ''
    s << content_tag(:span, '', class: 'btn_contextmenu_trigger icon-settings') do
      content_tag(:span, '', class: 'tooltip')
    end
    s.html_safe
  end

  def easy_project_template_query_additional_ending_buttons(project, options = {})
    s = ''
    return s unless EasyLicenseManager.has_license_limit?(:active_project_limit)

    parent_id = params[:project] && params[:project][:parent_id]
    s << link_to(content_tag(:span, l(:button_create_project_from_template)), show_create_project_template_path(id: project, project: { parent_id: parent_id }, assign_entity_id: params[:assign_entity_id], assign_entity_type: params[:assign_entity_type]), class: 'button-mini-positive', title: l(:title_button_template_create_project)) if Project.allowed_to_create_project_from_template?
    if params[:tab] != 'project_from_template'
      s << content_tag(:span, content_tag(:span, '', class: 'tooltip'), title: l(:title_additional_context_menu), class: 'btn_contextmenu_trigger icon-settings')
    end
    s.html_safe
  end

  def easy_broadcast_query_additional_ending_buttons(easy_broadcast, options = {})
    s = ''
    s << link_to(content_tag(:span, l(:button_show), :class => 'tooltip'), easy_broadcast_path(easy_broadcast), :class => 'icon icon-zoom-in', :title => l(:button_show)) if easy_broadcast.visible?
    s << link_to(content_tag(:span, l(:button_edit), :class => 'tooltip'), edit_easy_broadcast_path(easy_broadcast), title: l(:button_edit), :class => 'icon icon-edit', remote: true) if easy_broadcast.editable?
    s << link_to(content_tag(:span, l(:button_delete), :class => 'tooltip'), easy_broadcast_path(easy_broadcast), :method => :delete, :data => { :confirm => l(:text_are_you_sure) }, :class => 'icon icon-del', :title => l(:button_delete)) if easy_broadcast.deletable?
    s.html_safe
  end
end
