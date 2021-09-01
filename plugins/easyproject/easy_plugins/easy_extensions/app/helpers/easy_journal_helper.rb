# require 'helpers/journals_helper'
module EasyJournalHelper
  include JournalsHelper
  include CustomFieldsHelper

  MULTIPLE_VALUES_DETAIL = Struct.new(:property, :prop_key, :custom_field, :old_value, :value)

  def easy_journal_render_history(easy_journals, options = {})
    if options.key?(:entity) && easy_journals.present?
      options[:collapsible] = true if !options.key?(:collapsible)

      journals = ''

      journals << controller.render_to_string(:partial => 'journals/journal', :locals => options, :collection => easy_journals, :as => 'journal')

      js = ''
      if options[:loader]
        js = link_to("#{l(:label_show_all)} <i class=\"icon-keyboard-arrow-down\"></i>".html_safe, load_journals_path(journalized_type: options[:entity].class.name, journalized_id: options[:entity].id, update_element_id: "easy-journal-history#{options[:modul_uniq_id]}"), remote: true, id: "load-more-easy-journal-history#{options[:modul_uniq_id]}", class: 'journals_link_show_all button')
      end

      if options[:collapsible]
        content_tag(:div, :class => 'box easy-entity-journal', :id => 'history') do
          toggling_container("easy-journal-history#{options[:modul_uniq_id]}", User.current, { :heading => l(:label_history) + ':' }.merge(options)) { journals.html_safe }
        end + js.html_safe
      else
        content_tag(:div, journals.html_safe, id: "easy-journal-history#{options[:modul_uniq_id]}") + js.html_safe
      end
    end
  end

  # if entity is passed as options[:entity], than db queries are saved( 150ms average )
  def easy_journal_details_to_strings(details, no_html = false, options = {})
    journal         = options[:journal] # All details come from single journal
    strings         = []
    values_by_field = {}
    details.each do |detail|
      if detail.property == 'cf'
        field = detail.custom_field
        if field && field.multiple?
          values_by_field[field] ||= { :added => [], :deleted => [] }
          if detail.old_value
            values_by_field[field][:deleted] << detail.old_value
          end
          if detail.value
            values_by_field[field][:added] << detail.value
          end
          next
        end
      end
      journal          ||= detail.journal
      options[:entity] ||= journal.journalized
      strings << show_easy_journal_detail(detail, no_html, options)
    end
    if values_by_field.present?
      values_by_field.each do |field, changes|
        if changes[:added].any?
          detail       = MULTIPLE_VALUES_DETAIL.new('cf', field.id.to_s, field)
          detail.value = changes[:added]
          strings << show_easy_journal_detail(detail, no_html, options)
        end
        if changes[:deleted].any?
          detail           = MULTIPLE_VALUES_DETAIL.new('cf', field.id.to_s, field)
          detail.old_value = changes[:deleted]
          strings << show_easy_journal_detail(detail, no_html, options)
        end
      end
    end
    strings
  end

  def render_journal_details(journal, options = {})
    details = journal.visible_details
    return '' if details.empty? || !User.current.pref.display_journal_details
    strings = easy_journal_details_to_strings(details, false, { :entity => journal.journalized, :journal => journal }.merge(options))
    content_tag(:ul, strings.each_with_index.map { |string, i| content_tag(:li, string, :class => journal.important_details_map[i] ? 'important' : '') }.join.html_safe, :class => 'details')
  end

  # DO NOT USE WITHOUT easy_journal_details_to_strings
  # options:
  # => :no_html = true/false (default je false)
  # => :only_path = true/false (default je true)
  def show_easy_journal_detail(detail, no_html = false, options = {})
    only_path = options.key?(:only_path) ? options[:only_path] : true
    multiple  = false
    show_diff = false
    field     = detail.prop_key.to_s.gsub(/\_id$/, '')

    if detail.property != 'cf'
      entity = options[:entity]
      entity ||= detail.journal.journalized

      date_columns       = %w(due_date start_date effective_date) + entity.journalized_options[:format_detail_date_columns]
      time_columns       = %w(closed_on) + entity.journalized_options[:format_detail_time_columns]
      reflection_columns = %w(project_id parent_id status_id tracker_id assigned_to_id priority_id category_id fixed_version_id author_id activity_id issue_id user_id easy_closed_by_id) + entity.journalized_options[:format_detail_reflection_columns]
      boolean_columns    = %w(is_private) + entity.journalized_options[:format_detail_boolean_columns]
      hours_columns      = %w(estimated_hours) + entity.journalized_options[:format_detail_hours_columns]

      if detail.property == 'attr' && entity.class.respond_to?(:currency_options)
        currency_columns = /^(#{entity.class.currency_options.map { |x| x[:price_method] }.join('|')})_([A-Z]{3})$/
      end

      format_entity_journal_detail_method = "format_#{entity.class.name.underscore}_attribute"

      if detail.property == 'attr' && respond_to?(format_entity_journal_detail_method)
        attribute = EasyQueryColumn.new(field)
        # formating from EntityAttributeHelper
        value     = send(format_entity_journal_detail_method, entity.class, attribute, detail.value, { entity: entity, no_link: true, no_progress_bar: true })
        old_value = send(format_entity_journal_detail_method, entity.class, attribute, detail.old_value, { entity: entity, no_link: true, no_progress_bar: true })

        # set nil if EntityAttributeHelper not formated value
        value     = nil if value == detail.value
        old_value = nil if old_value == detail.old_value
      end
    end

    if detail.property == 'entity'
      detail_old_entity = detail.old_value ? JSON::load(detail.old_value) : nil
      detail_entity = detail.value ? JSON::load(detail.value) : nil
    end

    case detail.property
    when 'attr'
      label = entity.class.human_attribute_name(field) if entity && field.present?
      case detail.prop_key
      when *date_columns
        value     ||= begin
          detail.value && format_date(detail.value.to_date)
        rescue nil
        end
        old_value ||= begin
          detail.old_value && format_date(detail.old_value.to_date)
        rescue nil
        end
      when *time_columns
        date_changed = begin
          detail.value.nil? || detail.old_value.nil? || Date.parse(detail.value) != Date.parse(detail.old_value)
        rescue nil
        end
        value        ||= begin
          detail.value && format_time(Time.parse(detail.value), date_changed)
        rescue nil
        end
        old_value    ||= begin
          detail.old_value && format_time(Time.parse(detail.old_value), date_changed)
        rescue nil
        end
      when *reflection_columns
        @cached_names ||= easy_journal_names_by_reflection(entity, reflection_columns)
        if @cached_names.has_key?(detail.prop_key)
          value     ||= @cached_names[detail.prop_key][detail.value]
          old_value ||= @cached_names[detail.prop_key][detail.old_value]
        else
          logger.error "ERROR: Race condition encountered or bug found, prop_key: #{detail.prop_key}, entity: #{entity}, cached_names: #{@cached_names}"
        end
      when *boolean_columns
        value     ||= (l(detail.value == "0" ? :general_text_No : :general_text_Yes) unless detail.value.blank?)
        old_value ||= (l(detail.old_value == "0" ? :general_text_No : :general_text_Yes) unless detail.old_value.blank?)
      when *hours_columns
        value     ||= (easy_format_hours(detail.value, { no_html: true }) unless detail.value.blank?)
        old_value ||= (easy_format_hours(detail.old_value, { no_html: true }) unless detail.old_value.blank?)
      when currency_columns
        attribute_name = $1
        currency       = $2
        label          = l(:attribute_in_currency, attribute: entity.class.human_attribute_name(attribute_name), currency: EasyCurrency.get_name(currency))
        value          ||= (format_price(detail.value, currency, { no_html: true }) unless detail.value.blank?)
        old_value      ||= (format_price(detail.old_value, currency, { no_html: true }) unless detail.old_value.blank?)
      when 'description', 'easy_repeat_settings'
        show_diff = true
      when /(.*)country_code/
        label     = l(:"field_#{$1}country")
        value     = ISO3166::Country[detail.value]&.translation(I18n.locale.to_s)
        old_value = ISO3166::Country[detail.old_value]&.translation(I18n.locale.to_s)
      end
    when 'cf'
      #if they are preloaded(they should be) than this is quicker, but otherwise... :(
      if options[:entity].respond_to?(:custom_field_values)
        cv           = options[:entity].custom_field_values.detect { |cfv| cfv.custom_field_id == detail.prop_key.to_i }
        custom_field = cv.custom_field if cv
      end
      custom_field ||= custom_field = detail.custom_field
      if custom_field
        label = custom_field.translated_name
        if custom_field.format.class.change_no_details
          no_details = true
        elsif custom_field.format.class.change_as_diff
          show_diff = true
        else
          multiple = custom_field.multiple?
          if detail.value
            cv              = CustomFieldValue.new
            cv.custom_field = custom_field
            cv.value        = detail.value
            cv.customized   = options[:entity]
            cv.customized   = detail.journal.journalized if options[:entity].nil? && detail.respond_to?(:journal)
            value           = show_value(cv, !no_html)
          end
          if detail.old_value
            cv              = CustomFieldValue.new
            cv.custom_field = custom_field
            cv.value        = detail.old_value
            cv.customized   = options[:entity]
            cv.customized   = detail.journal.journalized if options[:entity].nil? && detail.respond_to?(:journal)
            old_value       = show_value(cv, !no_html)
          end
        end
      end
    when 'attachment', 'attachment_version'
      label = l(:label_attachment)
    when 'relation'
      @journal_detail_issue_scope ||= Issue.visible
      if detail.value && !detail.old_value
        rel_issue = @journal_detail_issue_scope.find_by(:id => detail.value)
        value     = rel_issue.nil? ? "#{l(:label_issue)} ##{detail.value}" :
                        (no_html ? rel_issue : link_to_issue(rel_issue, :only_path => options[:only_path]))
      elsif detail.old_value && !detail.value
        rel_issue = @journal_detail_issue_scope.find_by(:id => detail.old_value)
        old_value = rel_issue.nil? ? "#{l(:label_issue)} ##{detail.old_value}" :
                        (no_html ? rel_issue : link_to_issue(rel_issue, :only_path => options[:only_path]))
      end
      relation_type = IssueRelation::TYPES[detail.prop_key]
      label         = l(relation_type[:name]) if relation_type
      label         ||= entity.class.human_attribute_name(detail.prop_key) if entity
    when 'tags'
      label     = l(:label_easy_tags)
      value     = detail.value.present? ? JSON.parse(detail.value) : []
      old_value = detail.old_value.present? ? JSON.parse(detail.old_value) : []
    when 'entity'
      label = format_journal_detail_entity_label(detail_old_entity ? detail_old_entity : detail_entity)
    end

    call_hook(:helper_issues_show_detail_after_setting, { detail: detail, label: label, value: value, old_value: old_value, options: options })
    call_hook(:helper_easy_journal_show_detail_after_setting, { detail: detail, label: label, value: value, old_value: old_value, options: options })

    # Set default format
    label     ||= detail.prop_key
    if detail.property == 'entity'
      value     ||= format_journal_detail_entity(detail_entity) if detail_entity
      old_value ||= format_journal_detail_entity(detail_old_entity) if detail_old_entity
    else
      value     ||= detail.value
      old_value ||= detail.old_value
    end

    if !no_html
      label = content_tag(:strong, label)

      if detail.old_value && !%w(relation tags).include?(detail.property)
        if !detail.value || detail.value.blank?
          old_value = content_tag(:del, old_value)
        else
          old_value = content_tag(:i, old_value)
        end
      end

      case detail.property
      when 'attachment'
        # Link to the attachment if it has not been removed
        if !value.blank? && (attachment = detail.journal.journalized.attachments.detect { |a| a.id == detail.prop_key.to_i })
          value = easy_journal_link_to_attachment(attachment, only_path: only_path)
        elsif detail.prop_key == l(:label_document)
          # dmsf
          value = content_tag(:i, h(value)) if value
        else
          # if attachment has been deleted...
          value = content_tag(:del, h(value)) if value
        end
      when 'attachment_version'
        if !value.blank? && (attachment_version = find_attachment_version(detail, entity))
          value = easy_journal_link_to_attachment(attachment_version, only_path: only_path)
        else
          value = content_tag(:del, h(value)) if value
        end
      when 'tags'
        # do nothing here
      else
        value = content_tag(:i, h(value), class: 'new-value') if value
      end
    end

    if no_details
      s = l(:text_journal_changed_no_detail, label: label).html_safe
    elsif show_diff
      s = l(:text_journal_changed_no_detail, label: label)
      unless no_html
        diff_link = link_to('diff',
                            diff_journal_url(detail.journal_id, detail_id: detail.id, only_path: options[:only_path]),
                            title: l(:label_view_diff))
        s << " (#{ diff_link })"
      end
      s.html_safe
    elsif !detail.value.blank?
      case detail.property
      when 'attr', 'cf', 'entity'
        if detail.old_value.present?
          label += ' (' + format_journal_detail_entity(detail.journal.journalized.as_journal_detail_value) + ')' if (detail.property == 'entity' && detail.journal.journalized_type != entity.class.name)
          l(:text_journal_changed, label: label, old: old_value, new: value).html_safe
        elsif multiple
          l(:text_journal_added, label: label, value: value).html_safe
        else
          l(:text_journal_set_to, label: label, value: value).html_safe
        end
      when 'attachment', 'attachment_version', 'relation'
        l(:text_journal_added, label: label, value: value).html_safe
      when 'tags'
        formatted_value     = (no_html ? value : render(partial: 'easy_taggables/tags', formats: 'html', locals: { tag_list: value })) if value
        formatted_old_value = (no_html ? old_value : render(partial: 'easy_taggables/tags', formats: 'html', locals: { tag_list: old_value })) if old_value

        if value.present? && old_value.present?
          l(:text_journal_changed, label: label, old: content_tag(:i, formatted_old_value), new: content_tag(:i, formatted_value)).html_safe
        elsif value.present?
          l(:text_journal_added, label: label, value: content_tag(:i, formatted_value)).html_safe
        elsif old_value.present?
          l(:text_journal_deleted, label: label, old: content_tag(:del, formatted_old_value)).html_safe
        end
      else
        ''
      end
    else
      l(:text_journal_deleted, label: label, old: old_value).html_safe
    end
  end

  def find_attachment_version(detail, entity)
    attachment_version = nil
    entity.attachments.each do |a|
      attachment_version = a.versions.detect { |v| v.id == detail.prop_key.to_i }
      break unless attachment_version.nil?
    end
    attachment_version
  end

  def easy_journal_link_to_attachment(a, options = {})
    versions_count = 0
    if a.is_a?(Attachment)
      versions_count = a.versions.size
      a = a.versions.sort_by(&:version).first if versions_count > 1
    end
    value = link_to_attachment(a, download: false, only_path: options[:only_path])
    if a.is_a?(AttachmentVersion) || versions_count > 1
      value << " v#{a.version}"
    end
    if options[:only_path] != false && (a.is_text? || a.is_image?)
      value << ' '
      value << link_to(l(:button_view),
                       { controller: 'attachments', action: 'show',
                         id:         a, filename: a.filename, version: !a.is_a?(Attachment) || nil },
                       class: 'icon icon-magnifier',
                       title: l(:title_show_attachment))
    end
    value
  end

  # Find the name of an associated record stored in the field attribute
  def easy_journal_names_by_reflection(entity, reflection_columns)
    assoc_class_list = entity.class.reflect_on_all_associations(:belongs_to).select(&:constructable?).map { |x| [x.foreign_key.to_s, x.klass] }.to_h
    value_hash       = Hash.new { |hash, key| hash[key] = Set.new }
    out              = {}
    entity.journals.joins(:details).distinct.where(journal_details: { prop_key: reflection_columns }).pluck("#{JournalDetail.table_name}.prop_key, #{JournalDetail.table_name}.value, #{JournalDetail.table_name}.old_value").each do |prop_key, value, old_value|
      value_hash[prop_key] << value << old_value
    end
    value_hash.each do |(prop_key, values)|
      if assoc_class_list[prop_key]
        out[prop_key] = assoc_class_list[prop_key].where(id: values.to_a).map { |record| [record.id.to_s, record.try(:name) || record.to_s] }.to_h
      end
    end
    out
  end

  def render_api_journal(journal, api, options = {})
    api.journal :id => journal.id do
      render_api_journal_body(journal, api, options)
    end
  end

  def render_api_journal_body(journal, api, options = {})
    api.user(:id => journal.user_id, :name => journal.user.name) unless journal.user.nil?
    api.notes options[:textilizable] ? textilizable(journal, :notes) : journal.notes
    api.created_on journal.created_on
    api.private_notes journal.private_notes
    api.array :details do
      journal.visible_details.each do |detail|
        api.detail :property => detail.property, :name => detail.prop_key do
          api.old_value detail.old_value
          api.new_value detail.value
        end
      end
    end
  end

  def format_journal_detail_entity(entity)
    method_name = ('format_' + entity['class'].underscore + '_journal_detail_value').to_sym
    if respond_to? method_name
      send(method_name, entity)
    else
      entity['name']
    end
  end

  def format_journal_detail_entity_label(entity)
    method_name = ('format_' + entity['class'].underscore + '_journal_detail_value_label').to_sym
    if respond_to? method_name
      send(method_name, entity)
    else
      l('label_' + entity['class'].underscore)
    end
  end

end
IssuesHelper.include(EasyJournalHelper)
