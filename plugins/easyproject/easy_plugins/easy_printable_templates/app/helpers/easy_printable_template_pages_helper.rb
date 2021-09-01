module EasyPrintableTemplatePagesHelper

  def prepare_values_for_textilizable(tokens, result)
    case Setting.text_formatting
      when 'textile'
        tokens.each do |token, value|
          result.gsub!(Regexp.new("%\s?#{token}\s?%"), "<easypre value=\"#{token}\"></easypre>")
        end
        RedCloth3::ALLOWED_TAGS << 'easypre'
    end
  end

  def prepare_values_after_textilizable(tokens, result, entity)
    case Setting.text_formatting
      when 'textile'
        RedCloth3::ALLOWED_TAGS.delete_if { |x| x == 'easypre' }
        result.gsub!(Regexp.new("<easypre value=\"(#{tokens.keys.join('|')})\"></easypre>")) do
          value = tokens[$1]
          value = value.call if value.is_a?(Proc)
          escape_gsub_value(value)
        end
      else
        result.gsub!(Regexp.new("%\s?(#{tokens.keys.join('|')})\s?%")) do
          value = tokens[$1]
          value = value.call if value.is_a?(Proc)
          escape_gsub_value(value)
        end
    end

    parse_images(entity, result)
  end

  def parse_images(entity, result)
    if entity && entity.respond_to?(:attachments) && entity.attachments.present?
      result.gsub!(ApplicationHelper::EASY_LINKS_RE) do |m|
        identifier = $~[:identifier1] || $~[:identifier2] || $~[:identifier3]
        if identifier
          name = identifier.gsub(%r{^"(.*)"$}, "\\1")
          name = CGI.unescapeHTML(name)
          if attachment = Attachment.latest_attach(entity.attachments, name)
            if attachment.image?
              link_to_attachment(attachment, text: thumbnail_tag(attachment, {size: 800}))
            else
              link_to_attachment(attachment, only_path: true, download: false, class: 'attachment')
            end
          else
            m
          end
        else
          m
        end
      end
    end
  end

  # "aaa bbb ccc".gsub(/bbb/, "ddd \\' ddd")
  # => "aaa ddd  ccc ddd ccc"
  #
  # "aaa bbb ccc".gsub(/bbb/, "ddd \\\\' \\\' \\' \' ' ddd")
  # => "aaa ddd \\'  ccc  ccc ' ' ddd ccc"
  def escape_gsub_value(value)
    value = value.to_s
    value.gsub(/[\\]+'/, "'")
  end

  def replace_easy_printable_template_page_text(page_text, entity = nil)
    result = page_text.to_s.dup

    tokens, t = {}, nil
    if entity.is_a?(EasyQuery)
      t = easy_printable_template_page_create_replacable_tokens_from_entity_easy_query(entity)
    elsif entity
      m = "easy_printable_template_page_create_replacable_tokens_from_entity_#{entity.class.name.underscore}".to_sym
      if respond_to?(m)
        t = send(m, entity)
      end
    end

    if params[:additional_tokens]
      params[:additional_tokens].each do |name, token|
        if name.end_with?('_base64')
          name = name.sub(/_base64$/, '')
          token = Base64.decode64(token)
        end

        tokens[name] = Redmine::CodesetUtil.to_utf8(token, nil)
      end
    end

    tokens.merge!(t) if t.is_a?(Hash)

    tokens.merge!(easy_printable_template_page_create_replacable_tokens_from_others)

    call_hook(:helper_replace_easy_printable_template_page_text, {tokens: tokens, entity: entity, page_text: page_text})

    prepare_values_for_textilizable(tokens, result)

    result = Redmine::WikiFormatting.to_html('HTML', result)

    result.gsub(Regexp.new("%\s?query_(\\d+)\s?%")).each do
      easy_query = EasyQuery.find_by(id: $1)
      if easy_query
        easy_query.project = @project if @project
        t = easy_printable_template_page_create_replacable_tokens_from_entity_easy_query(easy_query)
        tokens["query_#{easy_query.id}"] = t['query']
      end
    end

    prepare_values_after_textilizable(tokens, result, entity)

    result.html_safe
  end

  def easy_printable_template_page_create_replacable_tokens_from_others
    tokens = {}

    tokens['today'] = format_date(Date.today)
    tokens['now'] = format_time(Time.now)
    tokens['year'] = Date.today.year.to_s
    tokens['last_month_number'] = Date.today.prev_month.month.to_s
    tokens['this_month_number'] = Date.today.month.to_s
    tokens['last_month_name'] = month_name Date.today.prev_month.month
    tokens['this_month_name'] = month_name Date.today.month
    tokens["([a-z_]*)?cf_\\d+(_text)?"] = ''

    tokens.merge!(easy_printable_template_page_create_replacable_tokens_from_hash(params['tokens'])) if params['tokens']

    tokens
  end

  def easy_printable_template_page_create_replacable_tokens_from_hash(params_hash)
    tokens = {}

    params_hash.each do |token_key, token_value|
      if token_key == 'qr_text'
        qr_text = Base64.urlsafe_decode64(token_value)

        if img = EasyQr.generate_image(qr_text)
          tokens['easy_short_url_small_qr'] = image_tag(img.resize(64, 64).to_data_url)
          tokens['easy_short_url_medium_qr'] = image_tag(img.resize(256, 256).to_data_url)
          tokens['easy_short_url_large_qr'] = image_tag(img.resize(512, 512).to_data_url)
        end
      end
    end

    tokens
  end

  def easy_printable_template_page_create_replacable_tokens_from_entity_project(project)
    return {} unless project.is_a?(Project)

    tokens = {}

    tokens['project_id'] = project.id
    tokens['project_name'] = project.name
    tokens['project_description'] = project.description
    tokens['project_start_date'] = format_date(project.start_date)
    tokens['project_due_date'] = format_date(project.due_date)
    tokens['project_author'] = project.author.nil? ? l(:label_nobody) : project.author.name
    tokens['project_journal_comments'] = proc { format_html_project_attribute(Project, EasyQueryColumn.new(:journal_comments, {}), '', {entity: project}) }

    project.custom_field_values.each do |cf_value|
      tokens["project_cf_#{cf_value.custom_field.id}"] = proc { show_value(cf_value) }
    end

    tokens
  end

  def easy_printable_template_page_create_replacable_tokens_from_entity_issue(issue)
    return {} unless issue.is_a?(Issue)
    tokens = {}

    tokens['task_id'] = issue.id
    tokens['task_tracker'] = issue.tracker.nil? ? '' : h(issue.tracker.name)
    tokens['task_project'] = issue.project.nil? ? '' : h(issue.project.name)
    tokens['task_subject'] = h(issue.subject)
    tokens['task_description'] = issue.description
    tokens['task_due_date'] = format_date(issue.due_date)
    tokens['task_category'] = issue.category.nil? ? '' : h(issue.category.name)
    tokens['task_status'] = issue.status.nil? ? '' : h(issue.status.name)
    tokens['task_assigned_to'] = issue.assigned_to.nil? ? l(:label_nobody) : h(issue.assigned_to.name)
    tokens['task_priority'] = issue.priority.nil? ? '' : h(issue.priority.name)
    tokens['task_milestone'] = issue.fixed_version.nil? ? '' : h(issue.fixed_version.name)
    tokens['task_author'] = h(issue.author.name) if issue.author
    tokens['task_created_on'] = format_time(issue.created_on)
    tokens['task_updated_on'] = format_time(issue.updated_on)
    tokens['task_start_date'] = format_date(issue.start_date)
    tokens['task_done_ratio'] = issue.done_ratio
    tokens['task_estimated_hours'] = issue.estimated_hours.nil? ? '' : easy_format_hours(issue.estimated_hours)
    tokens['task_total_spent_hours'] = easy_format_hours(issue.total_spent_hours)

    issue.visible_custom_field_values.each do |cf_value|
      tokens["task_cf_#{cf_value.custom_field.id}"] = proc { show_value(cf_value) }
      if cf_value.custom_field.field_format == 'easy_lookup'
        lookup_entity_klass = cf_value.custom_field.settings['entity_type'].constantize rescue nil
        lookup_entity = lookup_entity_klass.where(id: cf_value.to_s).first
        if lookup_entity && lookup_entity_klass.respond_to?(:safe_attributes)
          lookup_entity_klass.safe_attributes.map(&:first).flatten.each do |attr_name|
            next unless lookup_entity.respond_to?(attr_name)
            tokens["task_cf_#{cf_value.custom_field.id}_#{lookup_entity_klass.name.underscore}_#{attr_name}"] = proc { lookup_entity.send(attr_name) }
          end
        end
        if lookup_entity && lookup_entity.respond_to?(:visible_custom_field_values)
          lookup_entity.visible_custom_field_values.each do |lookup_entity_cf_value|
            tokens["task_cf_#{cf_value.custom_field.id}_#{lookup_entity_klass.name.underscore}_cf_#{lookup_entity_cf_value.custom_field.id}"] = proc { show_value(lookup_entity_cf_value) }
          end
        end
      end
    end

    if issue.project
      tokens.merge!(easy_printable_template_page_create_replacable_tokens_from_entity_project(issue.project))
    end

    tokens
  end

  def easy_printable_template_page_create_replacable_tokens_from_entity_easy_query(easy_query)
    return {} unless easy_query.is_a?(EasyQuery)

    tokens = {}

    sort_clear
    sort_init(easy_query.sort_criteria_init)
    sort_update(easy_query.sortable_columns)

    case easy_query.entity.name
      when 'Project'
        t = Project.arel_table
        easy_query.add_additional_statement t[:easy_is_easy_template].eq(false).to_sql
    end

    if easy_query.grouped?
      entities = easy_query.groups({:order => sort_clause, :include_entities => true})
    else
      entities = easy_query.entities({:order => sort_clause})
    end

    if easy_query.respond_to?(:project) && easy_query.project.present?
      tokens.merge!(
        easy_printable_template_page_create_replacable_tokens_from_entity_project(easy_query.project)
      )
    end

    tokens['query'] = render(partial: easy_query.easy_query_entity_partial_view,
                             locals: { query: easy_query,
                                       entities: entities,
                                       options: { preloaded: true, editable: false } })

    tokens
  end

end
