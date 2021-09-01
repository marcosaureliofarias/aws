module EasyPatch
  module IssuesHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :details_to_strings, :easy_extensions
        alias_method_chain :issue_estimated_hours_details, :easy_extensions
        alias_method_chain :issue_spent_hours_details, :easy_extensions
        alias_method_chain :render_descendants_tree, :easy_extensions
        alias_method_chain :show_detail, :easy_extensions

        # TODO: make some permission resolver
        #       now only this is needed
        #
        def render_api_issue_permissions(api, issue)
          permissions = params[:include_permissions]

          case permissions
          when Array
            permissions = permissions.map(&:to_s)
          when String
            permissions = permissions.split(',')
          else
            return
          end

          items = []

          permissions.map!(&:strip)
          permissions.each do |permission|
            case permission
            when 'add_comment'
              items << { name: permission, result: issue.notes_addable? }

            when 'view_estimated_hours'
              items << {
                  name:   permission,
                  result: !issue.disabled_core_fields.include?('estimated_hours') &&
                              User.current.allowed_to?(:view_estimated_hours, issue.project)
              }

            when 'edit_estimated_hours'
              items << { name: permission, result: issue.safe_attribute?('estimated_hours') }
            end
          end

          if items.empty?
            return
          end

          api.array :permissions do
            items.each do |item|
              api.permission do
                api.name item[:name]
                api.result item[:result]
              end
            end
          end
        end

        def newform_assignable_users_options(issue, project)
          project ||= issue.project
          grouped_options_for_select(entity_assigned_to_collection_for_select_options(issue, project), issue.assigned_to_id, prompt: '')
        end

        def options_for_issues(issues, selected, user = nil)
          user ||= User.current

          html = '<option></option>'
          html << options_from_collection_for_select(issues, :id, :to_s, selected)
          html
        end

        def return_issues_members_for_restrictions_users
          m = [l(:select_option_issue_restrictions_users_blank), nil]
          m.concat(@issue.assignable_users.map { |a| [a.name, a.id] })
          m
        end

        def issues_relations_field_tag(field_name, field_id, values = [], options = {})
          selected_values = EasyExtensions::FieldFormats::EasyLookup.entity_ids_to_lookup_values('Issue', values, :display_name => :subject)
          easy_modal_selector_field_tag('Issue', 'link_with_subject', field_name, field_id, selected_values, options)
        end

        def render_ancestors_tree(issue)
          s = '<form action=""><table class="list issues ancestors">'
          issue_list(issue.ancestors.includes(:status, :tracker, :assigned_to, :priority, :project).order(:lft)) do |child, level|
            s << content_tag('tr',
                             content_tag('td', check_box_tag("ids[]", child.id, false, :id => nil), :class => 'checkbox hide-when-print') +
                                 content_tag('td', link_to_issue(child, :truncate => 60, :project => (issue.project_id != child.project_id)), :class => 'subject') +
                                 content_tag('td', child.status, :class => 'status') +
                                 content_tag('td', link_to_user(child.assigned_to), :class => 'assigned_to') +
                                 content_tag('td', child.disabled_core_fields.include?('done_ratio') ? '' : progress_bar(child.done_ratio, :width => '80px'), :class => 'done_ratio') +
                                 content_tag('td', easy_issue_query_additional_ending_buttons(child), :class => 'easy-query-additional-ending-buttons hide-when-print'),
                             :class   => "#{child.css_classes} issue-#{child.id} hascontextmenu #{level > 0 ? "idnt idnt-#{level}" : nil}",
                             :onclick => "EASY.utils.goToUrl('#{issue_path(child)}', event)")
          end
          s << '</table></form>'
          s << context_menu(issues_context_menu_path, 'table.list.issues.ancestors')
          s.html_safe
        end

        def render_visible_issue_attributes_for_edit(issue, form, options = {})
          s = '<div class="splitcontent">'
          s << '<div class="splitcontentleft">'
          s << (render_visible_issue_attribute_for_edit_assigned_to_id(issue, form, options) || '')
          s << (render_visible_issue_attribute_for_edit_status_id(issue, form, options) || '')
          s << (render_visible_issue_attribute_for_edit_restrictions_users(issue, form, options) || '')
          s << (render_visible_issue_attribute_for_edit_done_ratio(issue, form, options) || '')
          s << (render_visible_issue_attribute_for_edit_easy_email_to(issue, form, options) || '')

          s << (call_hook(:helper_issues_render_visible_issue_attribute_for_edit_bottom_left, { :issue => issue, :form => form, :options => options }) || '')

          s << '</div>'
          s << '<div class="splitcontentright">'
          s << (render_visible_issue_attribute_for_edit_priority_id(issue, form, options) || '')
          s << (render_visible_issue_attribute_for_edit_due_date(issue, form, options) || '')
          s << (render_visible_issue_attribute_for_edit_easy_email_cc(issue, form, options) || '')

          s << (call_hook(:helper_issues_render_visible_issue_attribute_for_edit_bottom_right, { :issue => issue, :form => form, :options => options }) || '')

          s << '</div>'
          s << '</div>'
          s << '<div>'
          s << '</div>'
          s << '<div id="visible-custom-fields" style="clear:both">'
          s << render(:partial => 'issues/edit_form_updatable_attributes', :locals => { :show_on_more_form => false })
          s << '</div>'
          s.html_safe
        end

        def render_hidden_issue_attributes_for_edit(issue, form, options = {})
          s = '<div class="splitcontent">'
          s << '<div class="splitcontentleft">'
          s << (render_hidden_issue_attribute_for_edit_tracker_id(issue, form, options) || '')
          s << (render_hidden_issue_attribute_for_edit_author_id(issue, form, options) || '')
          s << (render_hidden_issue_attribute_for_edit_category_id(issue, form, options) || '')
          s << (render_hidden_issue_attribute_for_edit_fixed_version_id(issue, form, options) || '')
          s << (render_hidden_issue_attribute_for_edit_parent_id(issue, form, options) || '')

          s << (call_hook(:helper_issues_render_hidden_issue_attribute_for_edit_bottom_left, { :issue => issue, :form => form, :options => options }) || '')

          s << '</div>'
          s << '<div class="splitcontentright">'
          s << (render_hidden_issue_attribute_for_edit_start_date(issue, form, options) || '')
          s << (render_hidden_issue_attribute_for_edit_estimated_hours(issue, form, options) || '')
          s << (render_hidden_issue_attribute_for_edit_is_private(issue, form, options) || '')
          s << content_tag(:div, render(:partial => 'issues/edit_issue_repeat_options', :locals => { :issue => issue }), :id => 'edit_issue_repeat_options')

          s << (call_hook(:helper_issues_render_hidden_issue_attribute_for_edit_bottom_right, { :issue => issue, :form => form, :options => options }) || '')
          s << '</div>'
          s << '</div>'
          s.html_safe
        end

        def render_visible_issue_attribute_for_edit_assigned_to_id(issue, form, options = {})
          return unless issue.safe_attribute?('assigned_to_id') && issue.tracker && !issue.tracker.easy_distributed_tasks?

          required_assignee = issue.required_attribute?('assigned_to_id')
          content_tag(:p,
                      label_tag('issue_assigned_to_id', l(:field_assigned_to), class: required_assignee ? 'required' : '') +
                          easy_autocomplete_tag("#{form.object_name}[assigned_to_id]",
                                                { name: issue.assigned_to&.name, id: issue.assigned_to&.id },
                                                easy_autocomplete_path('assignable_principals_issue', issue_id: issue.id, project_id: @project.id, required: required_assignee),
                                                preload:                   false,
                                                required:                  required_assignee,
                                                root_element:              'users',
                                                html_options:              { class: 'assigned-to-id', id: 'issue_assigned_to_id' },
                                                force_autocomplete:        true,
                                                easy_autocomplete_options: {
                                                    activate_on_input_click: true,
                                                    widget:                  'catcomplete',
                                                    delay:                   50,
                                                    minLength:               0
                                                },
                                                onchange:                  "EASY.utils.updateForm('#issue-form', '#{j issue_ajax_path(issue, options)}')"))

        end

        def render_issue_attribute_for_inline_edit_assigned_to_id(issue, options = {})
          return unless issue.safe_attribute?('assigned_to_id') && issue.tracker && !issue.tracker.easy_distributed_tasks?
          required_assignee = issue.required_attribute?('assigned_to_id')
          input_name        = 'issue[assigned_to_id]'

          easy_autocomplete_tag('issue[assigned_to_id]',
                                { name: issue.assigned_to&.name, id: issue.assigned_to&.id },
                                easy_autocomplete_path('assignable_principals_issue', issue_id: issue.id, project_id: @project&.id, required: required_assignee),
                                preload:                   false,
                                required:                  required_assignee,
                                root_element:              'users',
                                html_options:              { class: 'assigned-to-id-inline', id: 'issue_assigned_to_id_inline' },
                                force_autocomplete:        true,
                                easy_autocomplete_options: {
                                    activate_on_input_click: true,
                                    widget:                  'catcomplete',
                                    delay:                   50,
                                    minLength:               0,
                                    append_to:               '.editable-container'
                                })
        end


        def render_visible_issue_attribute_for_edit_status_id(issue, form, options = {})
          return unless issue.safe_attribute?('status_id')
          content_tag(:p,
                      form.select(:status_id, (@allowed_statuses.collect { |p| [p.name, p.id] }), { :required => true }, {
                          :onchange => "EASY.utils.updateForm('#issue-form', '#{j issue_ajax_path(issue, options)}')" }),
                      :class => 'status-id') if @allowed_statuses.any?
        end

        def render_visible_issue_attribute_for_edit_restrictions_users(issue, form, options = {})
          content_tag(:p,
                      label_tag('restrictions_users', l(:label_restrictions_users)) +
                          select_tag('restrictions_users[]', options_for_select(return_issues_members_for_restrictions_users), :id => 'restrictions_users') +
                          link_to_function('', 'EASY.utils.toggleMultiSelect(\'restrictions_users\', \'\');', :class => 'toggle-bullet textcon-plus'),
                      :class => 'restrictions-users') if User.current.allowed_to?(:view_restrictions_users, issue.project) && EasySetting.value('edit_issue_columns_list', issue.project).include?('restrictions_users')
        end

        def render_visible_issue_attribute_for_edit_priority_id(issue, form, options = {})
          return unless issue.safe_attribute?('priority_id')
          content_tag(:p,
                      form.select(:priority_id, (@priorities.collect { |p| [p.name, p.id] }), { :required => true }, {}),
                      :class => 'priority-id')
        end

        def render_visible_issue_attribute_for_edit_due_date(issue, form, options = {})
          return unless issue.safe_attribute?('due_date')
          content_tag(:p,
                      form.date_field(:due_date, :size => 10, :required => issue.required_attribute?('due_date')) +
                          calendar_for('issue_due_date').html_safe, :class => 'due-date')
        end

        def render_visible_issue_attribute_for_edit_easy_email_to(issue, form, options = {})
          return unless issue.safe_attribute?('easy_email_to')
          content_tag(:p,
                      form.text_area(:easy_email_to, class: 'auto-expand', required: issue.required_attribute?('easy_email_to'), placeholder: call_hook(:placeholder_email_autocomplete))
          )
        end

        def render_visible_issue_attribute_for_edit_easy_email_cc(issue, form, options = {})
          return unless issue.safe_attribute?('easy_email_cc')
          content_tag(:p,
                      form.text_area(:easy_email_cc, class: 'auto-expand', label: :field_email_cc, required: issue.required_attribute?('easy_email_cc'), placeholder: call_hook(:placeholder_email_autocomplete))
          )

        end

        def render_visible_issue_attribute_for_edit_meeting_datetime(issue, form, options = {})
          res = ''
          res << content_tag(:p,
                             form.text_field(:start_date, :size => 10, :required => issue.required_attribute?('start_date'), :tabindex => 110) +
                                 calendar_for('issue_start_date').html_safe +
                                 content_tag(:span, select_time(issue.author.user_time_in_zone(issue.easy_start_date_time || Time.now), { :minute_step => 5, :ignore_date => true, :prefix => 'issue[easy_start_date_time]' }, :disabled => !issue.attributes_editable?), :class => 'meeting_times'),
                             :class => 'nowrap')
          res << content_tag(:p,
                             form.text_field(:due_date, :size => 10, :required => issue.required_attribute?('due_date')) +
                                 calendar_for('issue_due_date').html_safe +
                                 content_tag(:span, select_time(issue.author.user_time_in_zone(issue.easy_due_date_time || Time.now), { :minute_step => 5, :ignore_date => true, :prefix => 'issue[easy_due_date_time]' }, :disabled => !issue.attributes_editable?), :class => 'meeting_times'),
                             :class => 'due-date')
          date_js = 'var due_date_id = "issue_due_date";
                  var start_date_id = "issue_start_date";
                  if ( $("#"+due_date_id).val() == "" ) {
                    $("#"+due_date_id).val($("#"+start_date_id).val());
                  }
                  var user_changed_due_date = ($("#"+due_date_id).val() != $("#"+start_date_id).val());
                  $("#"+start_date_id).change(function(){
                    if ( !user_changed_due_date ) {
                      $("#"+due_date_id).val($("#"+start_date_id).val());
                    }
                  });
                  $("#"+due_date_id).change(function(){
                    user_changed_due_date = true;
                  });'
          res << late_javascript_tag(date_js)
          res.html_safe
        end

        def render_visible_issue_attribute_for_edit_done_ratio(issue, form, options = {})
          return unless issue.safe_attribute?('done_ratio') && Issue.use_field_for_done_ratio?
          content_tag(:p,
                      form.select(:done_ratio, ((0..10).to_a.collect { |r| ["#{r * 10} %", r * 10] }), { :required => issue.required_attribute?('done_ratio') }),
                      :class => 'done-ratio')
        end

        def render_hidden_issue_attribute_for_edit_tracker_id(issue, form, options = {})
          if issue.safe_attribute?('tracker_id') || issue.tracker_id_changed?
            content_tag(:p,
                        form.select(:tracker_id, trackers_options_for_select(issue), { :required => true }, { :tabindex => 40,
                                                                                                              :onchange => "EASY.utils.updateForm('#issue-form', '#{j issue_ajax_path(issue, options)}')" })
            )
          end
        end

        def render_hidden_issue_attribute_for_edit_author_id(issue, form, options = {})
          return unless issue.safe_attribute?('author_id')

          content_tag(:p,
                      label_tag('issue_author_id', "#{l(:field_author)} *", class: 'required') +
                          easy_autocomplete_tag("#{form.object_name}[author_id]",
                                                { name: issue.author&.name, id: issue.author&.id },
                                                easy_autocomplete_path('assignable_principals_issue', issue_id: issue.id, project_id: @project.id, required: true),
                                                preload:                   false,
                                                required:                  true,
                                                root_element:              'users',
                                                html_options:              { class: 'author-id', id: 'issue_author_id' },
                                                force_autocomplete:        true,
                                                easy_autocomplete_options: {
                                                    activate_on_input_click: true,
                                                    widget:                  'catcomplete',
                                                    delay:                   50,
                                                    minLength:               0
                                                }))
        end

        def render_hidden_issue_attribute_for_edit_category_id(issue, form, options = {})
          return unless issue.safe_attribute?('category_id') && @project.issue_categories.any?
          content_tag(:p,
                      form.select(:category_id, (issue_category_tree_options_for_select(@project.issue_categories, :selected => issue.category_id)), { :include_blank => true, :required => issue.required_attribute?('category_id') }, {})
          )
        end

        def render_hidden_issue_attribute_for_edit_fixed_version_id(issue, form, options = {})
          return unless issue.safe_attribute?('fixed_version_id') && issue.assignable_versions.any?
          content_tag(:p, form.select(:fixed_version_id, version_options_for_select(issue.assignable_versions, issue.fixed_version), { :include_blank => true, :required => issue.required_attribute?('fixed_version_id') }, { :tabindex => 90, :onchange => "EASY.utils.updateForm('#issue-form', '#{j issue_ajax_path(issue, options)}')" })
          )
        end

        def render_hidden_issue_attribute_for_edit_parent_id(issue, form, options = {})
          return unless issue.safe_attribute?('parent_issue_id')
          content_tag(:p, :class => 'easy-autocomplete-parent_id') do
            parent_val = EasyExtensions::FieldFormats::EasyLookup.entity_to_lookup_values(issue.parent_issue || issue.parent) || {}
            label_tag(:parent_issue_id, l(:field_parent_issue)) +
                form.hidden_field(:parent_issue_id, :value => '', :id => '') +
                easy_modal_selector_field_tag('Issue', 'link_with_subject', "#{form.object_name}[parent_issue_id]", "#{form.object_name}_parent_issue_id", parent_val, :multiple => false, :url => { :modal_project_id => issue.project_id, :parent_selection => true })
          end
        end

        def render_hidden_issue_attribute_for_edit_tag_list(issue, form, options = {})
          return unless issue.safe_attribute?('tag_list')
          content_tag(:p, :class => 'easy-tag-list-field') do
            label_tag(:issue_tag_list, l(:label_easy_tags)) +
                easy_tag_list_autocomplete_field_tag(issue, 'issue', id: 'issue_tag_list')
          end
        end

        def render_hidden_issue_attribute_for_edit_start_date(issue, form, options = {})
          return unless issue.safe_attribute?('start_date')
          content_tag(:p,
                      form.date_field(:start_date, :size => 10, :required => issue.required_attribute?('start_date'), :tabindex => 110) +
                          calendar_for('issue_start_date').html_safe,
                      :class => 'nowrap')
        end

        def render_hidden_issue_attribute_for_edit_estimated_hours(issue, form, options = {})
          return unless @project.module_enabled?(:time_tracking) && issue.safe_attribute?('estimated_hours') && User.current.allowed_to?(:view_estimated_hours, @project) && issue.tracker && !issue.tracker.easy_distributed_tasks?
          content_tag(:p,
                      form.text_field(:estimated_hours, :size => 3, :required => issue.required_attribute?('estimated_hours'), :tabindex => 130) +
                          content_tag(:span, l(:field_hours))
          )
        end

        def render_hidden_issue_attribute_for_edit_is_private(issue, form, options = {})
          return unless EasySetting.value('enable_private_issues') && issue.safe_attribute_names.include?('is_private')
          content_tag(:p,
                      label_tag('issue_is_private', l(:field_is_private)) + form.check_box(:is_private, :no_label => true)
          )
        end

        def easy_issue_timer_button(issue, user = User.current)
          return unless EasyIssueTimer.active?(issue.project) && User.current.allowed_to?(:log_time, issue.project) && issue.editable?
          timer = issue.easy_issue_timers.where(user_id: user.id).running.last
          if timer && !timer.paused?
            links = ''
            links << link_to(l(:button_easy_issue_timer_stop), easy_issue_timer_stop_path(issue, timer_id: timer), class: 'button-mini icon icon-checked-circle', method: :post, title: l(:title_easy_issue_timer_button_stop), onclick: "$(this).css({'z-index': -1})")
            links << '&nbsp;'
            links << link_to(l(:button_easy_issue_timer_pause), easy_issue_timer_pause_path(issue, timer_id: timer), class: 'button-mini icon icon-pause', method: :post, title: l(:title_easy_issue_timer_button_pause), onclick: "$(this).css({'z-index': -1})")
            content_tag(:span, links.html_safe, class: 'easy-issue-timers-stop-n-pause-buttons', id: 'timer_buttons_for_' + dom_id(issue))
          else
            links = ''
            links << link_to(l((timer.nil? ? :button_easy_issue_timer_play : :button_easy_issue_timer_resume)), easy_issue_timer_play_path(issue, timer_id: timer), class: 'button-mini icon icon-play', method: :post, title: l(:title_easy_issue_timer_button_play), onclick: "$(this).css({'z-index': -1})")
            content_tag(:span, links.html_safe, class: 'easy-issue-timers-stop-n-pause-buttons', id: 'timer_buttons_for_' + dom_id(issue))
          end
        end

        def heading_issue(issue, editable = false)
          content = ''.html_safe
          content << avatar(issue.assigned_to, { :style => :small }).to_s.html_safe if issue.assigned_to
          content << h(issue)

          # Editable field
          content = content_tag(:span,
                                  editable ? content_tag(:span,
                                              content,
                                              :class => 'multieditable',
                                              :data  => { :type => 'text', :name => 'issue[subject]', :value => issue.subject }
                                  ) : content,
                                  :class => 'multiedit-on-h2'
          )

          # Favorite tag
          if User.current.favorite_issues.where(:id => issue.id).exists?
            fav_css = 'icon-fav favorited'
            title   = l(:label_unfavorite)
          else
            fav_css = 'icon-fav-off'
            title   = l(:label_favorite)
          end
          content << link_to('', favorite_issue_path(@issue), :method => :post, :remote => true, :class => "icon #{fav_css}", :id => "favorite_issue_#{@issue.id}", :title => title)

          content << link_to('', 'javascript:void(0)',
                             class: 'icon icon-view-modal',
                             id: "modal_issue_#{@issue.id}",
                             title: l(:label_open_modal_window),
                             onclick: "EasyVue.showModal('issue', #{issue.id}); document.addEventListener('vueModalIssueChanged', (evt)=>evt.detail.id === #{issue.id} && location.reload())")

          # Private
          if issue.is_private? && EasySetting.value(:enable_private_issues)
            content << content_tag(:div, content_tag(:span, '', :class => 'icon icon-watcher private', :title => l(:field_is_private)).html_safe, :class => 'contextual red').html_safe
          end

          # H2 with drag handler
          content_tag(:h2, content, :class => 'issue-detail-header', :data => { :entity_type => 'Issue', :entity_id => issue.id, :handler => true })
        end

        def issue_category_tree_with_level_and_name_prefix(issue_categories)
          IssueCategory.each_with_level(issue_categories) do |category, level|
            next if category.nil? || category.id.nil?

            name_prefix = (level > 0 ? '|&nbsp;&nbsp;' * level + '&#8627; ' : '')
            if name_prefix.length > 0
              name_prefix = name_prefix.slice(1, name_prefix.length)
            end

            yield(category, level, name_prefix.html_safe)
          end
        end

        def issue_category_tree_options_for_select(issue_categories, options = {})
          s = ''
          issue_category_tree(issue_categories) do |category, level|
            if category.nil? || category.id.nil?
              next
            end

            name_prefix = (level > 0 ? '|&nbsp;&nbsp;' * level + '&#8627; ' : '')
            if name_prefix.length > 0
              name_prefix = name_prefix.slice(1, name_prefix.length)
            end
            name_prefix = name_prefix.html_safe
            tag_options = { :value => category.id }
            if !options[:selected].nil? && category.id == options[:selected]
              tag_options[:selected] = 'selected'
            else
              tag_options[:selected] = nil
            end

            if !options[:current].nil? && options[:current].id == category.id
              tag_options[:disabled] = 'disabled'
            end

            tag_options.merge!(yield(category)) if block_given?
            s << content_tag('option', name_prefix + h(category), tag_options)
          end
          s.html_safe
        end

        def issue_category_tree(issue_categories, &block)
          IssueCategory.each_with_level(issue_categories, &block)
        end

        def render_issue_category_with_tree(category)
          s = ''
          if category.nil?
            return ''
          end
          ancestors = category.root? ? [] : category.ancestors.all
          if ancestors.any?
            s << '<ul class="attribute__list attribute__list--tree">'
            ancestors.each do |ancestor|
              s << '<li>' + content_tag('span', h(ancestor.name)) + "<ul #{"class='first-child'" if ancestor.root?}>"
            end
            s << '<li>'
          end

          s << content_tag('span', h(category.name), :class => 'issue_category')

          if ancestors.any?
            s << '</li></ul>' * (ancestors.size + 1)
          end
          s.html_safe
        end

        def render_issue_category_with_tree_inline(category)
          s = ''
          if category.nil?
            return ''
          end
          ancestors = category.root? ? [] : category.ancestors.all
          if ancestors.any?
            ancestors.each do |ancestor|
              s << content_tag('span', h(ancestor.name), :class => 'parent')
            end
          end

          s << content_tag('span', h(category.name), :class => 'issue_category')

          if ancestors.any?
            s = content_tag('span', s, { :class => 'issue_category_tree' }, false)
          end
          s.html_safe
        end

        def move_category_path(category, direction)
          url_for({ :controller => 'issue_categories', :action => 'move_category', :id => category.id, :direction => direction })
        end

        def issue_ajax_path(issue, options = {})
          return options[:issue_ajax_path] unless options[:issue_ajax_path].blank?

          update_issue_form_path(issue.project, issue)

        end

        def easy_link_to_spent_hours(issue, hours, options = {})
          format = options.delete(:format)
          link_to(easy_format_hours(hours, :format => format), easy_time_entries_path({ issue_id: issue, period: 'all', set_filter: '1' }.merge(options)), title: l(:sidebar_issue_spent_time))
        end

        def easy_issue_tabs(issue)
          tabs = []
          tabs << { name: 'comments', label: l(:label_comment_plural), trigger: 'EntityTabs.showComments(this)' }

          if @project && @project.module_enabled?('time_tracking')
            url = issue_render_tab_path(issue, tab: 'spent_time')
            tabs << { name: 'spent_time', label: l(:label_spent_time), trigger: "EntityTabs.showAjaxTab(this, '#{url}')" }
          end

          tabs << { name: 'history', label: l(:label_history), trigger: 'EntityTabs.showHistory(this)', partial: 'issues/tabs/history' }

          url = issue_render_tab_path(issue, tab: 'revisions')
          tabs << { name: 'revisions', label: l(:label_revision_plural), trigger: "EntityTabs.showAjaxTab(this, '#{url}')" }

          if EasySetting.value('show_easy_entity_activity_on_issue')
            url = issue_render_tab_path(issue, tab: 'easy_entity_activity')
            tabs << { name: 'easy-entity-activity', label: l(:label_easy_entity_activity), trigger: "EntityTabs.showAjaxTab(this, '#{url}')" }
          end

          call_hook(:helper_easy_issue_tabs, tabs: tabs, issue: issue)

          tabs
        end

        def issue_show_in_tree_link
          if session[sort_name] == 'tree'
            issues_link_params = request.query_parameters.merge({ :sort => '' })
            link_text          = l(:button_disable_show_query_in_tree)
            link_title         = l(:title_disable_show_query_in_tree)
          else
            issues_link_params = request.query_parameters.merge({ :sort => 'tree' })
            link_text          = l(:button_show_query_in_tree)
            link_title         = l(:title_show_query_in_tree)
          end

          if params[:project_id].present?
            link_path = project_issues_path(params[:project_id], issues_link_params)
          else
            link_path = issues_path(issues_link_params)
          end

          link_to(link_text, link_path, :class => 'button icon icon-hierarchy', :title => link_title)
        end

        def issue_fields_table_rows
          r = IssueFieldsTableRows.new
          yield r
          r.to_html
        end

      end
    end

    class IssueFieldsTableRows < IssuesHelper::IssueFieldsRows

      def to_html
        html  = ''.html_safe
        blank = content_tag('th', '') + content_tag('td', '')
        size.times do |i|
          left  = @left[i] || blank
          right = @right[i] || blank
          html << content_tag('tr', left + right)
        end
        html
      end

      def cells(label, text, options = {})
        content_tag('th', "#{label}:", options) + content_tag('td', text, options)
      end
    end

    module InstanceMethods

      # options:
      # => :no_html = true/false (default je false)
      # => :only_path = true/false (default je true)
      def show_detail_with_easy_extensions(detail, no_html = false, options = {})
        show_easy_journal_detail(detail, no_html, options)
      end

      def details_to_strings_with_easy_extensions(details, no_html = false, options = {})
        easy_journal_details_to_strings(details, no_html, options)
      end

      def render_descendants_tree_with_easy_extensions(issue)
        s = '<form action=""><table class="list issues descendants">'
        issue_list(issue.descendants.visible.preload(:status, :tracker, :assigned_to, :priority, :project).order(:lft)) do |child, level|
          s << content_tag('tr',
                           content_tag('td', check_box_tag("ids[]", child.id, false, :id => nil), :class => 'checkbox hide-when-print') +
                             content_tag('td', link_to_issue(child, :truncate => 60, :project => (issue.project_id != child.project_id)), :class => 'subject') +
                             content_tag('td', child.status, :class => 'status') +
                             content_tag('td', link_to_user(child.assigned_to), :class => 'assigned_to') +
                             content_tag('td', child.disabled_core_fields.include?('done_ratio') ? '' : progress_bar(child.done_ratio, :width => '80px'), :class => 'done_ratio') +
                             content_tag('td', easy_issue_query_additional_ending_buttons(child) +
                               (child.safe_attribute?('parent_issue_id') ? link_to(content_tag(:span, l(:title_issue_remove_parent), :class => 'tooltip'), {:controller => 'easy_issues', :action => 'remove_child', :id => issue, :child_id => child}, :method => :delete, :remote => true, :data => {:confirm => l(:text_are_you_sure)}, :class => 'icon icon-del', :title => l(:title_issue_remove_parent)) : ''), :class => 'easy-query-additional-ending-buttons hide-when-print'),
                           :id => "issue-descendants-tree-child-#{child.id}",
                           :class => "#{child.css_classes} issue-#{child.id} hascontextmenu #{level > 0 ? "idnt idnt-#{level}" : nil}",
                           :onclick => "EASY.utils.goToUrl('#{issue_path(child)}', event)")
        end
        s << '</table></form>'
        s << context_menu(issues_context_menu_path, 'table.list.issues.descendants')
        s.html_safe
      end

      def issue_spent_hours_details_with_easy_extensions(issue)
        if issue.total_spent_hours > 0
          if issue.total_spent_hours == issue.spent_hours
            easy_link_to_spent_hours(issue, issue.spent_hours)
          else
            s = (issue.spent_hours > 0 ? easy_link_to_spent_hours(issue, issue.spent_hours) : '').html_safe
            s << " (#{l(:label_total)}: #{easy_link_to_spent_hours(issue, issue.total_spent_hours, with_descendants: true)})".html_safe
            s.html_safe
          end
        else
          easy_link_to_spent_hours(issue, 0)
        end
      end

      def issue_estimated_hours_details_with_easy_extensions(issue)
        if issue.total_estimated_hours
          if issue.total_estimated_hours == issue.estimated_hours
            easy_format_hours(issue.estimated_hours)
          else
            s = issue.estimated_hours ? easy_format_hours(issue.estimated_hours) : ''.html_safe
            s << " (#{l(:label_total)}: #{easy_format_hours(issue.total_estimated_hours)})".html_safe
            s.html_safe
          end
        end
      end
    end

  end

  module IssueFieldsRowsPatch
    def self.included(base)
      base.include(InstanceMethods)
      base.class_eval do
        alias_method_chain :cells, :easy_extensions
      end
    end

    module InstanceMethods
      def cells_with_easy_extensions(label, text, options = {})
        text_options    = options.delete(:text_options) || {}
        label_options   = options.delete(:label_options) || {}
        options[:class] = [options[:class] || '', 'attribute'].join(' ')
        value_span      = content_tag('span', text, text_options)
        label_class     = 'label'
        label_content   = label.blank? ? "" : label + ":"

        if label_options.has_key?(:title)
          label_class += ' ' + label_options[:class] if label_options.has_key?(:class)
          label_div   = content_tag('div', label_content, title: label_options[:title], class: label_class)
        else
          label_div = content_tag('div', label_content, class: label_class)
        end

        content_tag('div', label_div + content_tag('div', value_span, class: 'value'), options)
      end
    end
  end
end
EasyExtensions::PatchManager.register_helper_patch 'IssuesHelper', 'EasyPatch::IssuesHelperPatch'
EasyExtensions::PatchManager.register_helper_patch 'IssuesHelper::IssueFieldsRows', 'EasyPatch::IssueFieldsRowsPatch'
