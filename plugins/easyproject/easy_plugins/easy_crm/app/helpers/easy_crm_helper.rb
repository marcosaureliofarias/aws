module EasyCrmHelper

  # def render_api_easy_crm_case(api, easy_crm_case)
  #   api.easy_crm_case do
  #     api.id easy_crm_case.id
  #     api.name easy_crm_case.name
  #     api.description easy_crm_case.description if easy_crm_case.description.present?
  #     api.project(:id => easy_crm_case.project_id, :name => easy_crm_case.project.name)
  #     api.author(:id => easy_crm_case.author_id, :name => easy_crm_case.author.name)
  #     api.assigned_to(:id => easy_crm_case.assigned_to.id, :name => easy_crm_case.assigned_to.name) unless easy_crm_case.assigned_to.nil?
  #     api.easy_crm_case_status_id easy_crm_case.easy_crm_case_status_id
  #     api.contract_date easy_crm_case.contract_date if easy_crm_case.contract_date.present?
  #     api.email easy_crm_case.email if easy_crm_case.email.present?
  #     api.telephone easy_crm_case.telephone if easy_crm_case.telephone.present?
  #     api.price easy_crm_case.price if easy_crm_case.price.present?
  #     api.currency easy_crm_case.currency if easy_crm_case.currency.present?
  #     api.created_at easy_crm_case.created_at
  #     api.updated_at easy_crm_case.updated_at
  #     api.need_reaction easy_crm_case.need_reaction
  #     api.next_action easy_crm_case.next_action unless easy_crm_case.next_action.nil?
  #     api.is_canceled easy_crm_case.is_canceled
  #     api.is_finished easy_crm_case.is_finished
  #     api.lead_value easy_crm_case.lead_value
  #     api.probability easy_crm_case.probability
  #
  #     render_api_custom_values(easy_crm_case.visible_custom_field_values, api)
  #
  #     api.array :attachments do
  #       easy_crm_case.attachments.each do |attachment|
  #         render_api_attachment(attachment, api)
  #     end
  #     end if include_in_api_response?('attachments')
  #
  #     api.array :journals do
  #       @journals.each do |journal|
  #         render_api_journal(journal, api)
  #       end
  #     end if include_in_api_response?('journals') && !@journals.nil?
  #
  #     api.array :watchers do
  #       easy_crm_case.watcher_users.each do |user|
  #         api.user :id => user.id, :name => user.name
  #       end
  #     end if include_in_api_response?('watchers') && User.current.allowed_to?(:view_easy_crm_case_watchers, easy_crm_case.project)
  #
  #     call_hook(:helper_easy_crm_case_api, {:api => api, :easy_crm_case => easy_crm_case})
  #
  #     api.array :easy_crm_case_items do
  #       easy_crm_case.easy_crm_case_items.each do |easy_crm_case_item|
  #         render_api_easy_crm_case_item(api, easy_crm_case_item)
  #       end
  #     end
  #   end
  # end

  def render_api_easy_crm_case_item(api, easy_crm_case_item)
    # ActiveSupport::Deprecation.warn "This is already moved to EasySwagger::EasyCrmCaseItem"

    api.easy_crm_case_item do
      api.easy_crm_case_id easy_crm_case_item.easy_crm_case_id
      api.id easy_crm_case_item.id
      api.name easy_crm_case_item.name
      api.description easy_crm_case_item.description
      api.total_price easy_crm_case_item.total_price
      api.product_code easy_crm_case_item.product_code
      api.amount easy_crm_case_item.amount
      api.unit easy_crm_case_item.unit
      api.price_per_unit easy_crm_case_item.price_per_unit
      api.discount easy_crm_case_item.discount
      api.easy_external_id easy_crm_case_item.easy_external_id

      call_hook(:helper_easy_crm_case_item_api, {:api => api, :easy_crm_case_item => easy_crm_case_item})
    end
  end

  def render_api_easy_crm_case_status(api, easy_crm_case_status)
    api.easy_crm_case_status do
      api.id easy_crm_case_status.id
      api.name easy_crm_case_status.name
      api.internal_name easy_crm_case_status.internal_name
      api.position easy_crm_case_status.position
      api.is_default easy_crm_case_status.is_default
      api.created_at easy_crm_case_status.created_at
      api.updated_at easy_crm_case_status.updated_at
      api.is_easy_contact_required easy_crm_case_status.is_easy_contact_required
      api.is_closed easy_crm_case_status.is_closed
      api.is_won easy_crm_case_status.is_won
      api.is_paid easy_crm_case_status.is_paid
      api.is_provisioned easy_crm_case_status.is_provisioned
    end
  end

  def easy_crm_case_tabs(easy_crm_case)
    tabs = []
    tabs << { name: 'history', label: l(:label_history), trigger: 'EntityTabs.showHistory(this)', partial: 'easy_crm_cases/tabs/history' }
    tabs << { name: 'comments', label: l(:label_comment_plural), trigger: 'EntityTabs.showComments(this)' }


    if @project && @project.module_enabled?('time_tracking')
      url = render_tab_easy_crm_case_path(easy_crm_case, tab: 'spent_time')
      tabs << { name: 'spent_time', label: l(:label_spent_time), trigger: "EntityTabs.showAjaxTab(this, '#{url}')" }
    end

    if @project && EasySetting.value('show_easy_entity_activity_on_crm_case', @project)
      url = render_tab_easy_crm_case_path(easy_crm_case, tab: 'easy_entity_activity')
      tabs << { name: 'easy-entity-activity', label: l(:label_easy_entity_activity), trigger: "EntityTabs.showAjaxTab(this, '#{url}')" }
    end

    call_hook(:helper_easy_crm_case_tabs, tabs: tabs, easy_crm_case: easy_crm_case)

    tabs
  end

  def bulk_edit_invoice_error_messages(easy_crm_cases)
    messages = {}
    easy_crm_cases.each do |easy_crm_case|
      easy_crm_case.errors.full_messages.each do |message|
        messages[message] ||= []
        messages[message] << easy_crm_case
      end
    end
    #"#{message}: " + easy_crm_case.map(&:name).map {|n| n.split.first}.join(', ') if will be name of crm case long
    messages.map { |message, easy_crm_case|
      "#{message}: " + easy_crm_case.map(&:name).join(', ')
    }
  end

  def context_menu_merge_link(method, type)
    easy_autocomplete_tag(
      'easy_crm_case[merge_to_id]',
      { name: l(:"button_easy_crm_merge_cases_#{type}"), id: type },
      @easy_crm_cases.map { |c| { label: c.name,
                                  id: link_to(c.name, merge_easy_crm_cases_path(ids: @easy_crm_case_ids - [c.id], back_url: @back, merge_to_id: c.id), method: method)
      } },
      html_options: {
        id: "merge_to_context_menu_easy_crm_case_#{type}"
      },
      easy_autocomplete_options: {
        activate_on_input_click: 'true'
      },
      onchange: "
          if(!event.toElement || !($(event.toElement).find('a').length > 0)) {
            return;
          };
          $(event.toElement).find('a')[0].click();
          ",
      render_item: '
          function (ul, item) {
            return $("<li>")
            .data("item.autocomplete", item)
            .append(item.id)
            .appendTo(ul);
          }'
    )
  end

  def merge_input_attributes_name(object, attribute)
    object_name = object.name
    if attribute == 'created_at'
      value = object.created_at ? object.created_at.to_date : ''
    else
      value = format_entity_attribute(EasyCrmCase, attribute, object.send(attribute))
    end
    "#{value} - #{object_name}"
  end

  def merge_input_custom_field_name(crm_case, custom_field)
    custom_field_value = crm_case.custom_field_values.detect { |v| v.custom_field_id == custom_field.id }

    value = get_attribute_custom_field_formatted_value(crm_case, custom_field_value)
    "#{value} - #{crm_case.name}"
  end

  def merge_select_tags_builder(*args, &block)
    args << {} unless args.last.is_a?(Hash)
    options = args.last
    if args.first.is_a?(Symbol)
      options[:as] = args.shift
    end
    options[:builder] = EasyCrm::EasyCrmCaseMergeBuilder
    form_for(*args, &block)
  end

  def format_next_action(easy_crm_case)
    if easy_crm_case.all_day?
      format_date(easy_crm_case.next_action)
    else
      format_time(easy_crm_case.next_action)
    end
  end

  def easy_crm_case_kanban_project_settings
    setting = EasySetting.value(:easy_crm_case_kanban_project_settings, @project) || [{}]
    # backwards compatibility
    setting.is_a?(Hash) ? setting.values : setting
  end

  def render_visible_crm_case_attribute_for_edit_description(easy_crm_case, form, options={})
    return unless easy_crm_case.safe_attribute? 'description'
    content_tag(:p,
                form.text_area(:description, cols: 60, rows: 10, class: 'wiki-edit', no_label: true) + (wikitoolbar_for('easy_crm_case_description')))
  end

  def render_label_for_crm_case_field_by_workflow(easy_crm_case, form, attr, options = {})
    if options[:label]
      text = options[:label]
    else
      text = EasyCrmCase.human_attribute_name(attr)
    end
    if easy_crm_case.required_attribute?(attr) || options[:required] == true
      s = ''
      s << "<label class='required'>#{text} *</label>"
      s.html_safe
    else
      content_tag(:label, text)
    end
  end

  def link_to_easy_crm_case_new_template(options = {})
    templates_path({assign_entity_id: @easy_crm_case.id, assign_entity_type: @easy_crm_case.class.base_class}.merge(options))
  end

  def link_to_easy_crm_case_move(options = {})
    bulk_edit_easy_crm_cases_path({:id => @easy_crm_case.id}.merge(options))
  end

end
