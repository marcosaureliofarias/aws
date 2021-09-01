module EntityAttributeHelper
  include ERB::Util
  include EasyExtensions::EasyAttributeFormatter

  # Returns a formatted html value for query column
  # - entity_class - associated class of entity (query.entity), e.g.: Issue, Project, User, ...
  # - attribute - EasyEntityAttribute to format
  # - unformatted_value - Unformatted value of associated entity, which needed formatted
  # - options - :no_link => true - no html links will be rendered
  #           - :entity => associated entity, eg, issue, project, user, time_entry, ...
  #           - :no_html => passed to custom fields to do not display any html tags
  #           - :project => project from query, which helps to decide in some cases to take an specific setting
  #
  # This method looks for a concrete entity method or format_html_default_column is called
  def format_html_entity_attribute(entity_class, attribute, unformatted_value, options = {})
    return nil if entity_class.nil? || attribute.nil?
    attribute         = ensure_attribute(attribute, options)
    options[:no_link] = attribute.no_link unless options.has_key?(:no_link)
    # options.reverse_merge!({editable: false, not_editable: true})
    if !options[:without_assoc] && attribute.assoc
      if !options[:entity] || !(new_entity = options[:entity].send(attribute.assoc))
        new_entity_class = entity_class.reflections[attribute.assoc.to_s].klass
        attribute        = attribute.dup
        attribute.name   = attribute.short_name if attribute.short_name
        return format_html_entity_attribute(new_entity_class, attribute, unformatted_value, options.merge(without_assoc: true, entity: nil)).to_s.html_safe
      else
        attribute      = attribute.dup
        attribute.name = attribute.short_name if attribute.short_name
        if new_entity.is_a?(ActiveRecord::Associations::CollectionProxy)
          entities = Array(new_entity)
          entities.map! do |new_entity|
            options[:entity]  = new_entity
            unformatted_value = new_entity.__send__(attribute.name) if new_entity.respond_to?(attribute.name)
            format_html_entity_attribute(new_entity.class, attribute, unformatted_value, options.merge(:without_assoc => true)).to_s.html_safe
          end
          return entities.join(', ').html_safe
        else
          new_options  = { entity: new_entity, without_assoc: true }
          entity_class = new_entity ? new_entity.class : entity_class.reflections[attribute.assoc.to_s].klass
        end
      end
    end
    format_html_entity_attribute_method = "format_html_#{entity_class.format_html_entity_name}_attribute".to_sym if entity_class.respond_to?(:format_html_entity_name)
    format_html_entity_attribute_method ||= "format_html_#{entity_class.name.underscore}_attribute".to_sym

    if respond_to?(format_html_entity_attribute_method)
      formatted_value = send(format_html_entity_attribute_method, entity_class, attribute, unformatted_value, options.merge(new_options || {}))
    else
      formatted_value = format_html_default_entity_attribute(attribute, unformatted_value, options.merge(new_options || {}))
    end
    return formatted_value.to_s.html_safe
  end

  # Returns a formatted value for query column
  # - column - query column to format
  # - entity - associated instance of entity, e.g.: issue, project, user, ...
  # - options
  #
  # This method looks for a concrete entity method or format_default_column is called
  def format_entity_attribute(entity_class, attribute, unformatted_value, options = {})
    return nil if entity_class.nil? || attribute.nil?
    attribute = ensure_attribute(attribute, options)

    if !options[:without_assoc] && attribute.assoc
      if !options[:entity] || !(new_entity = options[:entity].send(attribute.assoc))
        new_entity_class = entity_class.reflections[attribute.assoc.to_s].klass
        return format_entity_attribute(new_entity_class, attribute, unformatted_value, options.merge(without_assoc: true, entity: nil)).to_s.html_safe
      else
        attribute      = attribute.dup
        attribute.name = attribute.short_name if attribute.short_name
        if new_entity.is_a?(ActiveRecord::Associations::CollectionProxy)
          entities = Array(new_entity)
          entities.map! do |new_entity|
            options[:entity]  = new_entity
            unformatted_value = new_entity.__send__(attribute.name) if new_entity.respond_to?(attribute.name)
            format_entity_attribute(new_entity.class, attribute, unformatted_value, options.merge(:without_assoc => true))
          end
          return entities.compact.join(', ').html_safe
        else
          new_options  = { entity: new_entity, without_assoc: true }
          entity_class = new_entity.class
        end
      end
    end

    if attribute.is_a?(EasyEntityCustomAttribute)
      return format_entity_custom_attribute(entity_class, attribute, unformatted_value, options.merge(new_options || {}))
    end
    format_entity_attribute_method = "format_#{entity_class.name.underscore}_attribute".to_sym
    formatted_value                = if respond_to?(format_entity_attribute_method)
                                       send(format_entity_attribute_method, entity_class, attribute, unformatted_value, options.merge(new_options || {}))
                                     else
                                       format_default_entity_attribute(attribute, unformatted_value, options.merge(new_options || {}))
                                     end
    formatted_value
  end

  def format_groupby_html_entity_attribute(entity_class, attribute, unformatted_value, options = {})
    options[:group_title] = true
    values             = []
    unformatted_values = Array.wrap(unformatted_value)
    attribute.each_with_index do |att, i|
      values << if unformatted_values[i].nil? || unformatted_values[i] == ''
                  l(:label_none)
                else
                  if att.name == :done_ratio
                    format_entity_attribute(entity_class, att, unformatted_values[i], options).to_s + '%'
                  else
                    if att.assoc && att.assoc_type == :has_many
                      if options[:entity] && options[:group]
                        grp        = Array.wrap(options[:group])[i]
                        new_entity = options[:entity].send(att.assoc).detect { |e| e.id == grp.to_i }
                        format_html_entity_attribute(att.assoc_class, att.dup.tap { |a| a.name = a.short_name; a.assoc = nil }, unformatted_values[i], options.merge(entity: new_entity))
                      else
                        unformatted_values[i]
                      end
                    else
                      new_options = att.is_a?(EasyEntityCustomAttribute) && att.custom_field.multiple? ? { entity: nil } : {}
                      format_html_entity_attribute(entity_class, att, unformatted_values[i], options.merge(new_options))
                    end
                  end
                end
    end
    if values.count <= 1
      values.first
    else
      content_tag(:div, class: 'multigrouping') do
        values.map { |v| "<span class=\"multigroup_element\">#{v}</span>" }.join('').html_safe
      end
    end
  end

  def format_groupby_entity_attribute(entity_class, attribute, unformatted_value, options = {})
    values             = []
    unformatted_values = Array.wrap(unformatted_value)
    attribute.each_with_index do |att, i|
      values << if unformatted_values[i].nil? || unformatted_values[i] == ''
                  l(:label_none)
                else
                  value = if att.assoc && att.assoc_type == :has_many
                            if options[:entity] && options[:group]
                              grp        = Array.wrap(options[:group])[i]
                              new_entity = options[:entity].send(att.assoc).detect { |e| e.id == grp.to_i }
                              format_entity_attribute(att.assoc_class, att.dup.tap { |a| a.name = a.short_name; a.assoc = nil }, unformatted_values[i], options.merge(entity: new_entity))
                            else
                              unformatted_values[i]
                            end
                          else
                            new_options = att.is_a?(EasyEntityCustomAttribute) && att.custom_field.multiple? ? { entity: nil } : {}
                            format_entity_attribute(entity_class, att, unformatted_values[i], options.merge(new_options))
                          end
                  value.to_s
                end
    end
    if values.count <= 1
      values.first
    else
      ('[' + values.join(', ') + ']')
    end
  end

  def format_html_issue_attribute(entity_class, attribute, unformatted_value, options = {})
    options[:inline_editable] = true if options[:inline_editable].nil?
    value                     = format_entity_attribute(entity_class, attribute, unformatted_value, options)

    case attribute.name
    when :project
      if value && !options[:no_link]
        if (options[:editable] || options[:editable].nil?) && options[:entity].present? && options[:entity].editable? && !options[:modal] && options[:entity].safe_attribute?('project_id')
          content = content_tag(:span, link_to_project(value), :class => 'editable')
          content << content_tag(:span, '', :class => 'icon-edit project-autocomplete-edit')

          content << easy_autocomplete_tag(
              'issue[project_id]',
              { name: value, id: value.id },
              easy_autocomplete_path('allowed_target_projects_on_move'),
              html_options:              {
                  id: "project_for_issue_#{options[:entity].id}"
              },
              wrapper_html_options:      {
                  style: 'display: none;'
              },
              easy_autocomplete_options: {
                  position: {
                      my:        "left top",
                      at:        "left bottom",
                      collision: "none"
                  }
              },
              root_element:              'projects',
              onchange:                  "if(!ui['item']) { return }; window.location = '#{issue_move_to_project_path(ids: [options[:entity].id])}' + '&project_id=' + ui['item']['id'] + '&back_url=' + encodeURIComponent(window.location.toString());"
          )
          content_tag(:span, content, :class => 'editable-parent')
        else
          link_to_project(value)
        end
      else
        h(value)
      end
    when :parent_project, :main_project
      if value && !options[:no_link]
        link_to_project(value)
      else
        h(value)
      end
    when :subject
      if options.has_key?(:wrap)
        value = value.scan(/(.{1,#{options[:wrap]}})/).flatten.join('<br/>').html_safe
      end
      entity_multieditable_tag(entity_class, 'subject', options[:no_link] ? h(value) : link_to(value, options[:entity]), options, { :value => unformatted_value.to_s })
    when :attachments
      if value
        truncate_objects(value) { |attach| attach.to_a.map! { |a| link_to_attachment(a, download: true, :class => 'attachment') } }
      end
    when :relations
      if value && options[:entity]
        value.collect { |relation| "#{l(relation.label_for(options[:entity]))} #{link_to_issue(relation.other_issue(options[:entity]))}" }.join(', ').html_safe
      end
    when :done_ratio
      if options[:no_progress_bar]
        value
      else
        progress_bar(value, :width => '50px', :title => "#{l(:label_done)} #{value} %")
      end
    when :description
      textilizable(value)
    when :created_on
      if options[:period]
        value
      elsif unformatted_value
        EasySetting.value('issue_created_on_date_format') == 'date' ? format_date_with_zone(unformatted_value) : format_time(unformatted_value)
      end
    when :spent_hours, :total_spent_hours, :remaining_timeentries, :total_remaining_timeentries, :total_estimated_hours
      easy_format_hours(unformatted_value, options)
    when :estimated_hours
      css_classes = ''
      if options[:entity].present? &&
          options[:entity].respond_to?(:safe_attribute?) &&
          options[:entity].safe_attribute?('estimated_hours')
        css_classes << 'multieditable'
      end
      content_tag(:span, easy_format_hours(unformatted_value, options), :class => css_classes,
                  data:                                                        {
                      name:  'issue[estimated_hours]',
                      type:  'hours',
                      value: (unformatted_value.nil? ? '' : unformatted_value)
                  }
      )
    when :spent_estimated_timeentries, :total_spent_estimated_timeentries
      float_num = unformatted_value.to_f
      n         = float_num > 100 ? -1 : float_num
      format_number(n, "%d %%" % float_num)
    when :category
      if options[:entity] && value
        render_issue_category_with_tree(value)
      else
        h(value)
      end
    when :due_date
      entity_multieditable_tag(entity_class, 'due_date', h(value), options, { :value => unformatted_value.to_s, :type => 'dateui' })
    when :start_date
      entity_multieditable_tag(entity_class, 'start_date', h(value), options, { :value => unformatted_value.to_s, :type => 'dateui' })
    when :priority
      entity_multieditable_tag(entity_class, 'priority_id', h(value), options,
                               { :value               => options[:entity].try(:priority_id), :type => 'select',
                                 :autocomplete_source => 'issue_priorities' })
    when :status
      entity_multieditable_tag(entity_class, 'status_id', h(value), options,
                               { :value               => options[:entity].try(:status_id), :type => 'select',
                                 :autocomplete_source => ['allowed_issue_statuses', { :issue_id => options[:entity].try(:id) }] })
    when :assigned_to
      link        = render_user_attribute(unformatted_value, value, options)
      tracker     = options[:entity].tracker if options[:entity]
      distributed = tracker.easy_distributed_tasks? if tracker
      editable    = (options[:editable] || options[:editable].nil?) && options[:entity]&.editable? && options[:entity]&.safe_attribute?('assigned_to_id')

      if distributed || !editable
        link
      else
        entity_multieditable_tag(entity_class, 'assigned_to_id', link, options,
                                 { value: options[:entity].try(:assigned_to_id), type: 'easy_autocomplete',
                                   tpl: render_issue_attribute_for_inline_edit_assigned_to_id(options[:entity])})
      end
    when :fixed_version
      entity_multieditable_tag(entity_class, 'fixed_version_id', h(value), options,
                               { :value               => options[:entity].try(:fixed_version_id), :type => 'select',
                                 :autocomplete_source => ['assignable_versions', { :issue_id => options[:entity].try(:id) }] })
    when :author, :easy_closed_by, :easy_last_updated_by
      content_tag(:span, render_user_attribute(unformatted_value, value, options)) if value
    when :easy_due_date_time_remaining
      easy_format_hours(unformatted_value, options) if unformatted_value
    when :easy_due_date_time
      format_time(unformatted_value) if unformatted_value
    when /status_time_/
      easy_format_hours(unformatted_value / 1.minute.to_f, options) if unformatted_value
    when :open_duration_in_hours
      easy_format_hours(unformatted_value / 1.hour.to_f, options) if unformatted_value
    when :name_and_cf
      subject_link = link_to(options[:entity].subject, options[:entity])
      "#{subject_link} - #{get_attribute_custom_field_formatted_value(options[:entity], attribute, :html => true)}"
    when :parent
      if value
        link_to_issue(value, {tracker: false})
      end
    else
      h(value)
    end

  end

  def format_issue_attribute(entity_class, attribute, unformatted_value, options = {})
    value = format_default_entity_attribute(attribute, unformatted_value, options)

    value = case attribute.name
            when :watchers
              if !unformatted_value.empty?
                unformatted_value.collect { |w| w.user.name if w.user }.compact.join(', ')
              else
                l(:label_nobody)
              end
            when :subject
              if options[:entity] && options[:entity].easy_is_repeating
                value + ' ' + l(:label_easy_issue_subject_reccuring_suffix)
              else
                value
              end
            when :attachments
              if value && options[:no_html]
                value.map(&:filename).join(', ')
              else
                value
              end
            when :spent_hours, :total_spent_hours, :remaining_timeentries, :total_remaining_timeentries, :total_estimated_hours, :estimated_hours
              options[:no_html] ? format_locale_number(unformatted_value) : easy_format_hours(unformatted_value, options)
            when :easy_due_date_time_remaining
              if time_value = unformatted_value.try(:to_time)
                hours = (time_value - Time.now) / 1.hour.to_f
                options[:no_html] ? format_locale_number(hours) : easy_format_hours(hours, options.reverse_merge(no_html: true))
              else
                ''
              end
            when :easy_due_date_time
              format_time(unformatted_value) if unformatted_value
            when /status_time_/
              if unformatted_value
                hours = unformatted_value / 1.minute.to_f
                options[:no_html] ? format_locale_number(hours) : easy_format_hours(hours, options.reverse_merge(no_html: true))
              end
            when :open_duration_in_hours
              if unformatted_value
                hours = unformatted_value / 1.hour.to_f
                options[:no_html] ? format_locale_number(hours) : easy_format_hours(hours, options.reverse_merge(no_html: true))
              end
            when :name_and_cf
              "#{options[:entity].subject} - #{get_attribute_custom_field_formatted_value(options[:entity], attribute)}"
            else
              value
            end

    value
  end

  def format_html_project_attribute(entity_class, attribute, unformatted_value, options = {})
    value = format_entity_attribute(entity_class, attribute, unformatted_value, options)

    case attribute.name
    when :name
      if options[:no_link] || (options[:entity] && (options[:entity].archived? || !User.current.allowed_to?(:view_project, options[:entity])))
        h(options[:entity])
      else
        link_to_project(options[:entity])
      end
    when :done_ratio, :completed_percent
      progress_bar(value, :width => '80px')
    when :users
      if options[:users_as_avatars] && options[:allow_avatar]
        unformatted_value.sort.map { |user|
          content_tag(:span, avatar(user, style: :small, title: user.name), class: 'tiles-avatar-container')
        }.join.html_safe
      else
        unformatted_value.sort.collect { |u| link_to_user(u) }.join(', ').html_safe
      end
    when :description
      textilizable(value)
    when :sum_of_timeentries, :remaining_timeentries, :sum_estimated_hours, :total_sum_estimated_hours, :total_remaining_timeentries, :total_spent_hours
      easy_format_hours(unformatted_value, options)
    when :author
      content_tag(:span, render_user_attribute(unformatted_value, value, options)) if value
    when :last_journal_comment
      if (en = options[:entity]) && !en.last_journal_comment.nil?
        return content_tag(:ul, content_tag(:li, format_project_comments_journal_line(en.last_journal_comment, true).html_safe))
      end
    when :journal_comments
      if (en = options[:entity]) && en.journal_comments.any?
        return content_tag(:ul) do
          content = ''
          en.journal_comments.each do |journal|
            content << content_tag(:li, format_project_comments_journal_line(journal, true).html_safe)
          end
          content.html_safe
        end
      end
      return ''
    when :easy_indicator
      es = case unformatted_value
           when Project::EASY_INDICATOR_OK then
             'easy-indicator-ok'
           when Project::EASY_INDICATOR_WARNING then
             'easy-indicator-warning'
           when Project::EASY_INDICATOR_ALERT then
             'easy-indicator-alert'
           end
      content_tag(:div, '', :class => "state-indicator-circle #{es}", :title => l(unformatted_value, :scope => [:easy_indicator, :titles])) if unformatted_value
    when :start_date, :due_date
      unless EasySetting.value("project_calculate_#{attribute.name}")
        entity_multieditable_tag(entity_class, "easy_#{attribute.name}", h(value), options,
                                 {
                                     :type  => 'dateui',
                                     :value => unformatted_value.to_s
                                 })
      else
        h(value)
      end
    when :name_and_cf
      "#{link_to_project(options[:entity])} - #{get_attribute_custom_field_formatted_value(options[:entity], attribute, :html => true)}"
    else
      h(value)
    end
  end

  def format_project_attribute(entity_class, attribute, unformatted_value, options = {})
    value = format_default_entity_attribute(attribute, unformatted_value, options)

    value = case attribute.name
            when :status
              case value.to_i
              when Project::STATUS_ACTIVE
                l(:project_status_active)
              when Project::STATUS_CLOSED
                l(:project_status_closed)
              when Project::STATUS_ARCHIVED
                l(:project_status_archived)
              when Project::STATUS_PLANNED
                l(:project_status_planned)
              end
            when :users
              value.sort.collect { |u| u.to_s }.join(', ')
            when :journal_comments
              if (en = options[:entity]) && en.journal_comments.any?
                return en.journal_comments.collect { |journal| format_project_comments_journal_line(journal) }.join(',')
              end
              return ''
            when :last_journal_comment
              if (en = options[:entity]) && !en.last_journal_comment.nil?
                format_project_comments_journal_line(en.last_journal_comment)
              else
                ''
              end
            when :easy_indicator
              if options[:no_html] == false && unformatted_value
                # 4 non-breakable spaces generates square (RBPDF has minimal CSS support)
                value = content_tag(:div, ('&nbsp;' * 4), :style => "background-color: #{Project::EASY_INDICATOR_COLORS[unformatted_value]}")
              elsif unformatted_value
                value = l(unformatted_value, :scope => [:easy_indicator, :titles])
              end
              value
            when :name_and_cf
              "#{options[:entity].name} - #{get_attribute_custom_field_formatted_value(options[:entity], attribute)}"
            else
              value
            end

    value
  end

  def format_html_version_attribute(entity_class, attribute, unformatted_value, options = {})
    value = format_entity_attribute(entity_class, attribute, unformatted_value, options)

    case attribute.name
    when :project
      if value && !options[:no_link]
        link_to_project(value)
      else
        h(value)
      end
    when :name
      if options[:no_link] || !options[:entity]
        h(value)
      else
        link_to(value, version_path(options[:entity]))
      end
    when :description
      truncate_html(textilizable(value), 255)
    when :completed_percent
      progress_bar(options[:entity] ? [options[:entity].closed_percent, unformatted_value] : unformatted_value, :width => '80px', :legend => ('%0.0f%%' % unformatted_value))
    when :name_and_date
      name_link = link_to(options[:entity].name, version_path(options[:entity]))
      "#{name_link} - #{format_date(options[:entity].effective_date)}"
    when :name_and_cf
      name_link = link_to(options[:entity].name, version_path(options[:entity]))
      "#{name_link} - #{get_attribute_custom_field_formatted_value(options[:entity], attribute, :html => true)}"
    else
      h(value)
    end
  end

  def format_version_attribute(entity_class, attribute, unformatted_value, options = {})
    value = format_default_entity_attribute(attribute, unformatted_value, options)

    case attribute.name
    when :status
      l("version_status_#{value}")
    when :sharing
      format_version_sharing(value)
    when :name_and_date
      "#{options[:entity].name} - #{format_date(options[:entity].effective_date)}"
    when :name_and_cf
      "#{options[:entity].name} - #{get_attribute_custom_field_formatted_value(options[:entity], attribute)}"
    else
      if value.nil?
        l(:label_none)
      else
        value
      end
    end
  end

  def format_html_easy_attendance_attribute(entity_class, attribute, unformatted_value, options = {})
    value = format_entity_attribute(entity_class, attribute, unformatted_value, options)

    case attribute.name
    when :spent_time
      if options[:entity] && unformatted_value && options[:entity].working_time
        format_number(unformatted_value - options[:entity].working_time, easy_format_hours(unformatted_value, options))
      elsif unformatted_value
        easy_format_hours(unformatted_value, options)
      end
    when :working_time
      easy_format_hours(unformatted_value, options)
    when :description
      textilizable(value)
    when :user
      content_tag(:span, render_user_attribute(unformatted_value, value, options))
    when :approved_by
      content_tag(:span, render_user_attribute(unformatted_value, value, options))
    when :arrival_user_ip
      if options[:entity] && !options[:entity].arrival_coordinates.blank? && !options[:no_html]
        "#{value} #{link_to_google_map(options[:entity].arrival_coordinates, :name => '')}"
      else
        value
      end
    when :departure_user_ip
      if options[:entity] && !options[:entity].departure_coordinates.blank? && !options[:no_html]
        "#{value} #{link_to_google_map(options[:entity].departure_coordinates, :name => '')}"
      else
        value
      end
    else
      h(value)
    end
  end

  def format_easy_attendance_attribute(entity_class, attribute, unformatted_value, options = {})
    value = format_default_entity_attribute(attribute, unformatted_value, options)
    case attribute.name
    when :easy_attedance_activity
      value.to_s
    when :approval_status, :previous_approval_status
      value ? l(:approval_statuses, scope: :easy_attendance)[value.to_s.to_sym] : l(:approval_not_required, scope: :easy_attendance)
    else
      value
    end
  end

  def format_user_attribute(entity_class, attribute, unformatted_value, options = {})
    value = format_default_entity_attribute(attribute, unformatted_value, options)

    case attribute.name
    when :easy_user_type
      value.to_s
    when :status
      l("status_#{::User::LABEL_BY_STATUS[value.to_i]}", default: '')
    when :roles
      scope = if @project && options[:entity] && !options[:modal]
                options[:entity].roles_for_project(@project)
              else
                value.to_a
              end
      scope.map(&:name).join(', ')
    when :name_and_cf
      "#{options[:entity].name} - #{get_attribute_custom_field_formatted_value(options[:entity], attribute)}"
    when :attendance_in_period_diff_working_time_percent, :time_entry_in_period_diff_working_time_percent, :working_attendance_percent
      number_to_percentage(unformatted_value * 100, precision: 2) if unformatted_value && unformatted_value.finite?
    when :easy_online_status
      l("easy_online_status_#{value}", default: '')
    else
      value
    end
  end


  def format_html_user_attribute(entity_class, attribute, unformatted_value, options = {})
    value = format_entity_attribute(entity_class, attribute, unformatted_value, options)

    case attribute.name
    when :name
      if options[:no_link]
        h(value)
      else
        link_to(value, user_path(options[:entity]))
      end
    when :login
      if options[:no_link]
        h(value)
      else
        link_to(render_user_attribute(options[:entity], value, options), user_path(options[:entity]))
      end
    when :auth_source
      if options[:no_link] || !unformatted_value
        h(value)
      else
        link_to(value, edit_auth_source_path(unformatted_value))
      end
    when :mail
      mail_to value
    when :easy_global_rating
      if value && (v = value.value)
        rating_stars(v)
      end
    when :easy_user_type
      (User.current.admin? && !options[:no_link] && unformatted_value) ? link_to(unformatted_value.to_s, edit_easy_user_type_path(unformatted_value)) : value
    when :roles
      scope = if @project && options[:entity] && !options[:modal]
                options[:entity].roles_for_project(@project)
              else
                unformatted_value.to_a
              end
      truncate_objects(scope) { |val| (User.current.admin? && !options[:no_link]) ? val.map { |r| link_to(r.name, edit_role_path(r)) } : val.map(&:name) }
    when :qr_code
      if options[:entity]
        # link_to_entity_mapper(content_tag(:i, '', :class => 'xl-icon icon-qr'), user_path(options[:entity], :format => 'qr'),  User, EasyExtensions::Export::EasyVcard, :title => 'QR code', :remote => true)
        vcard_generator = EasyExtensions::EasyEntityAttributeMappings::VcardMapper.new(options[:entity], EasyExtensions::Export::EasyVcard).map_entity
        if vcard_generator && vcard_export = Redmine::CodesetUtil.safe_from_utf8(vcard_generator.to_vcard, 'UTF-8')
          image_tag(EasyQr.generate_image(vcard_export.force_encoding('iso-8859-2'), { :size => '150' }).to_data_url)
          # render(:partial => 'easy_qr/easy_qr', :locals => {:size => 2, :easy_qr => EasyQr.generate_qr(vcard_export.force_encoding('iso-8859-2'))})
        end
      end
    when :name_and_cf
      name_link = link_to(options[:entity].name, user_path(options[:entity]))
      "#{name_link} - #{get_attribute_custom_field_formatted_value(options[:entity], attribute, :html => true)}"
    when /eaa_limit_accumulated|eaa_remaining_limit/
      content_tag(:span, h(value), class: ('red' if unformatted_value.to_f < 0))
    else
      h(value)
    end
  end

  alias_method :format_html_anonymous_user_attribute, :format_html_user_attribute
  alias_method :format_anonymous_user_attribute, :format_user_attribute

  def format_html_group_attribute(entity_class, attribute, unformatted_value, options = {})
    value = format_entity_attribute(entity_class, attribute, unformatted_value, options)

    case attribute.name
    when :lastname
      if options[:no_link] || options[:entity].blank?
        h(value)
      else
        link_to(value, edit_group_path(options[:entity]))
      end
    when :name_and_cf
      name_link = link_to(options[:entity].name, group_path(options[:entity]))
      "#{name_link} - #{get_attribute_custom_field_formatted_value(options[:entity], attribute, :html => true)}"
    else
      h(value)
    end
  end

  def easy_query_data_qroup_name(groups)
    groups = [groups] if groups.nil?
    Array.wrap(groups).map do |group|
      case group
      when TrueClass
        '1'
      when FalseClass
        '0'
      else
        group.to_s
      end
    end
  end

  def format_entity_custom_attribute(entity_class, attribute, unformatted_value, options)
    if options[:entity]
      cv                        = options[:entity].visible_custom_field_values.detect { |v| v.custom_field_id == attribute.custom_field.id }
      options[:inline_editable] = true if options[:inline_editable].nil? && options[:entity].respond_to?(:editable?) && options[:entity].editable?
    else
      cv              = CustomFieldValue.new
      cv.custom_field = attribute.custom_field
      cv.value        = unformatted_value.respond_to?(:id) ? unformatted_value.id.to_s : unformatted_value.to_s
    end
    if cv && cv.custom_field && cv.custom_field.date? && options[:period]
      format_period(Array(cv.value).first.to_time, options[:period])
    else
      show_value(cv, !options[:no_html], options)
    end
  end

  def format_html_document_attribute(entity_class, attribute, unformatted_value, options = {})
    value = format_entity_attribute(entity_class, attribute, unformatted_value, options)

    case attribute.name
    when :title
      if options[:no_link]
        h(value)
      else
        link_to(value, document_path(options[:entity]))
      end
    when :description
      textilizable(value)
    when :name_and_cf
      title_link = link_to(options[:entity].title, document_path(options[:entity]))
      "#{title_link} - #{get_attribute_custom_field_formatted_value(options[:entity], attribute, :html => true)}"
    else
      h(value)
    end

  end

  def format_html_time_entry_attribute(entity_class, attribute, unformatted_value, options = {})
    value = format_entity_attribute(entity_class, attribute, unformatted_value, options)

    case attribute.name
    when :project_root, :project
      if value && !options[:no_link]
        link_to_project(value)
      else
        h(value)
      end
    when :issue
      if value.is_a?(Issue) && !options[:no_link]
        link_to(value.subject, issue_path(value))
      else
        h(value)
      end
    when :comments
      content_tag :div, (value || '').html_safe
    when :hours, :estimated_hours
      easy_format_hours(unformatted_value, options)
      # when :user_roles
      #   value.collect{|r| r.name}.join(', ')
    when :user, :issue_assigned_to
      content_tag(:span, render_user_attribute(unformatted_value, value, options))
    when :issue_created_on
      if unformatted_value
        EasySetting.value('issue_created_on_date_format') == 'date' ? format_date_with_zone(unformatted_value) : format_time(unformatted_value)
      end
    when :issue_open_duration_in_hours
      easy_format_hours(unformatted_value / 1.hour, options) if unformatted_value
    when :entity
      link_to_entity(unformatted_value)
    else
      h(value)
    end

  end

  def format_time_entry_attribute(entity_class, attribute, unformatted_value, options = {})
    value = format_default_entity_attribute(attribute, unformatted_value, options)

    case attribute.name
    when :issue
      unless value
        l(:label_none)
      else
        value
      end
    when :hours, :estimated_hours
      format_locale_number(value)
    when :easy_range_from, :easy_range_to
      format_time(unformatted_value, false) if unformatted_value
    when :tmonth
      month_name(value.to_i)
    when :user_roles
      value.collect { |r| r.name }.join(', ')
    when :issue_open_duration_in_hours
      if unformatted_value
        hours = unformatted_value / 1.hour
        options[:no_html] ? format_locale_number(hours) : easy_format_hours(hours, options.reverse_merge(no_html: true))
      end
    when :entity_type
      l('label_' + (unformatted_value && unformatted_value.underscore || 'none'))
    else
      value
    end

  end

  def format_easy_issue_timer_attribute(entity_class, attribute, unformatted_value, options = {})
    value = format_default_entity_attribute(attribute, unformatted_value, options)

    case attribute.name
    when :issue
      unless value
        l(:label_none)
      else
        value
      end
    when :current_hours, :issue_estimated_hours
      format_locale_number(value)
    when :paused_at
      format_default_entity_attribute(attribute, unformatted_value.present?, options)
    else
      value
    end
  end

  def format_html_easy_issue_timer_attribute(entity_class, attribute, unformatted_value, options = {})
    value = format_entity_attribute(entity_class, attribute, unformatted_value, options)

    case attribute.name
    when :issue_project
      if value
        link_to_project(value)
      else
        h(value)
      end
    when :issue
      if value.is_a?(Issue)
        tooltip_id = "#{dom_id(value)}_#{Redmine::Utils.random_hex(8)}"
        content_tag :div, :class => 'tooltip', :id => tooltip_id do
          a = link_to_issue(value)
          a << ''
          a << late_javascript_tag("
                new easyClasses.EasyTooltip('#{j content_tag(:span, render_issue_tooltip(value), :class => 'tip')}', $('##{tooltip_id}'), 0,-30);
          ", priority: -5)
          a
        end
      else
        value
      end
    when :current_hours, :issue_estimated_hours
      easy_format_hours(unformatted_value, options)
    when :user
      content_tag(:span, render_user_attribute(unformatted_value, link_to_user(value), options))
    else
      h(value)
    end
  end

  def format_html_easy_entity_xml_import_attribute(entity_class, attribute, unformatted_value, options = {})
    format_html_easy_entity_import_attribute(entity_class, attribute, unformatted_value, options)
  end

  def format_html_easy_entity_import_attribute(entity_class, attribute, unformatted_value, options = {})
    value = format_entity_attribute(entity_class, attribute, unformatted_value, options)

    case attribute.name
    when :name
      if value
        link_to(value, easy_entity_import_path(options[:entity]))
      else
        h(value)
      end
    else
      h(value)
    end

  end

  def format_html_easy_entity_action_attribute(entity_class, attribute, unformatted_value, options = {})
    value = format_entity_attribute(entity_class, attribute, unformatted_value, options)

    case attribute.name
    when :name
      if options[:entity]
        link_to_easy_entity_action(options[:entity])
      else
        h(value)
      end
    else
      h(value)
    end

  end

  def format_html_easy_entity_activity_attribute(entity_class, attribute, unformatted_value, options = {})
    options[:inline_editable] = true
    value                     = format_entity_attribute(entity_class, attribute, unformatted_value, options)

    case attribute.name
    when :easy_entity_activity_attendees
      format_easy_entity_activity_attendees(unformatted_value, options)
    when :author
      entity_multieditable_tag(entity_class, 'author_id', render_user_attribute(unformatted_value, value, options), options,
                               {
                                   :autocomplete_source => ['assignable_users', { :entity_type => 'EasyEntityActivity', :entity_id => options[:entity].try(:id) }],
                                   :type                => 'select'
                               })
    when :start_time
      format_object(User.current.user_time_in_zone(unformatted_value))
    when :all_day, :is_finished
      entity_multieditable_tag(entity_class, attribute.name.to_s, h(value), options, { :value => unformatted_value, :type => 'select', :source => boolean_source })
    when :category
      entity_multieditable_tag(entity_class, 'category_id', value && value.name, options,
                               { :value               => options[:entity].try(:category_id), :type => 'select',
                                 :autocomplete_source => 'easy_entity_activity_category' })
    when :description
      entity_multieditable_tag(entity_class, 'description', value, options, { :value => value || '-' })
    when :entity
      link_to(unformatted_value.to_s, unformatted_value)
    else
      h(value)
    end

  end

  def format_easy_entity_activity_attribute(entity_class, attribute, unformatted_value, options = {})
    value = format_default_entity_attribute(attribute, unformatted_value, options)

    case attribute.name
    when :easy_entity_activity_attendees
      options[:no_html] = true
      format_easy_entity_activity_attendees(unformatted_value, options)
    else
      value
    end
  end

  def format_html_easy_page_attribute(entity_class, attribute, unformatted_value, options = {})
    value = format_entity_attribute(entity_class, attribute, unformatted_value, options)

    case attribute.name
    when :identifier
      link_to(value, custom_easy_page_path(value)) if !value.blank?
    when :url
      if options[:entity] && !options[:entity].identifier.blank?
        link_to(custom_easy_page_path(:identifier => options[:entity].identifier), custom_easy_page_url(:identifier => options[:entity].identifier))
      end
    when :translated_name
      if options[:entity] && (!options[:entity].has_template? || options[:entity].built_in?)
        path_options = { id: options[:entity].id }
        path_options.merge!(back_url: original_url) if options[:entity].built_in?
        link_to(value, edit_easy_page_path(path_options))
      else
        h(value)
      end
    else
      h(value)
    end
  end

  def format_html_easy_query_attribute(entity_class, attribute, unformatted_value, options = {})
    value = format_default_entity_attribute(attribute, unformatted_value, options)

    case attribute.name
    when :default_for_roles
      value.map { |x| x.name }.join(', ')
    when :name
      if options[:entity].present? && !(!options[:entity].class.global_project_context? && options[:entity].project_id)
        link_to(value, options[:entity].path)
      else
        value
      end
    when :visible_by_entities
      title = l(value[:visibility_title])
      if options[:group_title] && (query = options[:easy_query]) && query.group_by.include?('visible_by_entities')
        title
      else
        entity_names = value[:visible_entities].join(', ')
        title += ':' if entity_names.present?
        "#{title} #{entity_names}"
      end
    else
      h(value)
    end
  end

  def format_html_easy_broadcast_attribute(entity_class, attribute, unformatted_value, options = {})
    value = format_default_entity_attribute(attribute, unformatted_value, options)

    case attribute.name
    when :author
      link_to(value, user_path(unformatted_value)) if value
    when :easy_user_types
      value.map(&:name).join(',')
    else
      value
    end
  end

  private

  def format_project_comments_journal_line(journal, html = false)
    formated_journal = html ? textilizable(journal, :notes) : ActionController::Base.helpers.strip_tags(journal.notes)
    format_date(journal.created_on) << ' ' << formated_journal
  end

  def truncate_objects(scope, max = 10, separator = ',')
    diff    = scope.size - max
    objects = scope.first(max)
    str     = yield(objects).join("#{separator} ")
    str << "... (#{diff})" if diff > 0
    str
  end

  def entity_multieditable_class(options, attribute)
    if (options[:editable] || options[:editable].nil?) && options[:entity] && options[:entity].safe_attribute?(attribute)
      'multieditable'
    else
      ''
    end
  end

  def ensure_attribute(attribute, options = {})
    unless attribute.is_a?(EasyEntityAttribute)
      if attribute.start_with?('link_with_')
        attribute = EasyEntityAttribute.new(attribute.sub('link_with_', ''), options)
      elsif attribute == 'name_and_cf'
        attribute = EasyEntityNamedCustomAttribute.new(attribute, options[:custom_field], options)
      else
        attribute = EasyEntityAttribute.new(attribute, { :no_link => true }.merge(options))
      end
    end
    attribute
  end

  def entity_multieditable_tag(entity_class, attribute, value, options, data_options = {})
    data_options[:url] ||= url_to_entity(options[:entity], :format => 'json') if options[:entity] && options[:without_assoc]
    if (options[:editable] || options[:editable].nil?) && data_options[:autocomplete_source]
      data_options[:source] = easy_autocomplete_path(*data_options[:autocomplete_source])
    end
    content_tag :span, value, { :class => entity_multieditable_class(options, attribute), :data => {
        :name => "#{entity_class.name.underscore}[#{attribute}]",
        :type => 'text'
    }.merge(data_options)
    }
  end

  def boolean_source
    [{ text: ::I18n.t(:general_text_Yes), value: '1' }, { text: ::I18n.t(:general_text_No), value: '0' }].to_json
  end

  def format_html_default_entity_attribute(attribute, unformatted_value, options = {})
    value = format_default_entity_attribute(attribute, unformatted_value, options)

    return value
  end

  def format_default_entity_attribute(attribute, unformatted_value, options = {})
    # if options[:allow_avatar] && unformatted_value.class.name == 'User'
    #   value = render_user_attribute(unformatted_value, unformatted_value.name, options)
    # else
    return nil if unformatted_value.nil?

    value = case attribute.name
            when :tags
              if options[:no_html]
                unformatted_value.join(', ')
              else
                unformatted_value.map { |t| link_to(t.name, easy_tag_path(t.name)) }.join(', ').html_safe
              end
            when :name_and_cf
              "#{options[:entity].to_s} - #{get_attribute_custom_field_formatted_value(options[:entity], attribute)}"
            else
              case unformatted_value
              when Time
                options[:period] ? format_period(unformatted_value, options[:period]) : format_time(unformatted_value)
              when Date
                format_date(unformatted_value)
              when TrueClass
                l(:general_text_Yes)
              when FalseClass
                l(:general_text_No)
              when Float, BigDecimal
                format_locale_number(unformatted_value)
              else
                unformatted_value
              end
            end
    # end

    value
  end

  def render_user_attribute(entity, value, options_for_avatar = {})
    options_for_avatar.reverse_merge!(style: :small, no_link: true)

    to_return = ''
    # Maybe for allow showing avatars on any query?
    # EasySetting.value('show_avatars_on_query')

    # Show avatar of @query is not available or it is set
    @query    ||= @entity if @entity.is_a?(EasyQuery)
    if (options_for_avatar[:allow_avatar] != false) && (@query.nil? || (@query && @query.show_avatars?))
      to_return << avatar(entity, options_for_avatar)
    end
    to_return << content_tag(:span, h(value))
    to_return.html_safe
  end

  def get_attribute_custom_field_formatted_value(entity, attribute, options = {})
    options.reverse_merge!(:customized => nil, :html => false)

    if entity && attribute.respond_to?(:custom_field) && attribute.custom_field
      attribute.custom_field.format.formatted_value(self, attribute.custom_field, entity.custom_value_for(attribute.custom_field).try(:value), options[:customized], options[:html])
    end
  end

  def format_easy_entity_activity_attendees(unformatted_value, options)
    if (group = options[:group]) && options[:entity]
      if group == '_'
        l(:label_no_attendee)
      else
        entity_class_name, entity_id = group.split '_'
        attendee                     = options[:entity].easy_entity_activity_attendees.detect { |attendee| (attendee.entity_type == entity_class_name) && (attendee.entity_id.to_s == entity_id) }
        if attendee && (entity = attendee.entity)
          link_to_easy_entity_activity_attendee(entity, options)
        else
          group
        end
      end
    else
      Array.wrap(unformatted_value).map { |attendee| link_to_easy_entity_activity_attendee(attendee.entity, options) }.join(', ').html_safe
    end
  end

  def link_to_easy_entity_activity_attendee(entity, options)
    if entity.respond_to?(:visible?) && !entity.visible?
      '-'
    elsif options[:no_html]
      entity.to_s
    else
      link_to_entity(entity)
    end
  end

end
