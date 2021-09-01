module EasyPatch
  module ProjectsHelperPatch
    include Redmine::Export::PDF

    def self.included(base)
      base.include(InstanceMethods)
      base.class_eval do

        alias_method_chain :parent_project_select_tag, :easy_extensions
        alias_method_chain :project_settings_tabs, :easy_extensions

        def link_to_project_archive(project, options = {})
          css = options[:class] || 'button icon icon-archive'
          url = { :controller => 'projects', :action => 'archive', :id => project }.merge(options[:url] || {})
          link_to(l(:button_archive), url, :data => { :confirm => "#{project.name} \n\n #{l(:text_project_archive_confirmation)}" }, :method => :post, :class => css)
        end

        def link_to_project_unarchive(project, options = {})
          css = options[:class] || 'button icon icon-unlock'
          url = { :controller => 'projects', :action => 'unarchive', :id => project }.merge(options[:url] || {})
          link_to(l(:button_unarchive), url, :method => :post, :class => css)
        end

        def link_to_project_close(project, options = {})
          css = options[:class] || 'button icon icon-lock'
          url = { :controller => 'projects', :action => 'close', :id => project }.merge(options[:url] || {})
          link_to(l(:button_close), url, :data => { :confirm => "#{project.name} \n\n #{l(:text_project_close_confirmation)}" }, :method => :post, :class => css)
        end

        def link_to_project_reopen(project, options = {})
          css = options[:class] || 'button icon icon-unlock'
          url = { :controller => 'projects', :action => 'reopen', :id => project }.merge(options[:url] || {})
          link_to(l(:button_reopen), url, :data => { :confirm => "#{project.name} \n\n #{l(:text_project_reopen_confirmation)}" }, :method => :post, :class => css)
        end

        def link_to_project_copy(project, options = {})
          css = options[:class] || 'button icon icon-copy'
          url = { :controller => 'projects', :action => 'copy', :id => project, :admin => '1' }.merge(options[:url] || {})
          link_to(l(:button_copy), url, :class => css)
        end

        def link_to_project_delete(project, options = {})
          css = options[:class] || 'button icon icon-del'
          link_to(l(:button_delete), project_path(project), :method => :delete, :class => css)
        end

        def link_to_project_new_subproject(project, options = {})
          css = options[:class] || 'button icon icon-add'
          url = { :controller => 'projects', :action => 'new', :'project[parent_id]' => project.id, :back_url => url_for(params.to_unsafe_hash) }.merge(options[:url] || {})
          link_to(l(:label_subproject_new), url, :class => css, :title => l(:label_subproject_new))
        end

        def link_to_project_new_subtemplate(project, options = {})
          css = options[:class] || 'button icon icon-add'
          url = new_project_path({ :project => { :parent_id => project.id, :easy_is_easy_template => true }, :back_url => original_url }.merge(options[:url] || {}))
          link_to(l(:label_subtemplate_new), url, :class => css, :title => l(:label_subtemplate_new))
        end

        def link_to_project_new_subproject_from_template(project, options = {})
          css = options[:class] || 'button icon icon-add'
          url = { :controller => 'templates', :action => 'index', :'project[parent_id]' => project.id, :back_url => original_url }.merge(options[:url] || {})
          link_to(l(:label_new_subproject_from_template), url, :class => css, :title => l(:label_new_subproject_from_template))
        end

        def link_to_project_new_template_from_project(project, options = {})
          css = options[:class] || 'button icon icon-add'
          url = { :controller => 'templates', :action => 'add', :id => project, :back_url => original_url }.merge(options[:url] || {})
          link_to(l(:button_new_template_from_project), url, :class => css, :title => l(:title_button_template, :projectname => project.name))
        end

        def projects_relations_field_tag(field_name, field_id, selected_values = [], options = {})
          easy_modal_selector_field_tag('Project', 'link_with_name', field_name, field_id, selected_values, options)
        end

        def render_api_project(api, project)
          api.project do
            api.id(project.id)
            api.name(project.name)
            api.identifier(project.identifier)
            api.description(project.description)
            api.homepage(project.homepage)
            api.parent(:id => project.parent.id, :name => project.parent.name) if project.parent && project.parent.visible?
            api.status(project.status)
            api.is_public(project.is_public?)
            api.easy_is_easy_template(project.easy_is_easy_template)
            api.easy_start_date(project.easy_start_date) unless EasySetting.value('project_calculate_start_date', project)
            api.easy_due_date(project.easy_due_date) unless EasySetting.value('project_calculate_due_date', project)
            api.easy_external_id(project.easy_external_id)
            api.author(:id => project.author.id, :name => project.author.name, :easy_external_id => project.author.easy_external_id) if project.author
            api.sum_time_entries(project.sum_time_entries)
            api.sum_estimated_hours(project.sum_estimated_hours)
            api.currency(project.easy_currency.iso_code) if project.easy_currency
            api.default_version(id: project.default_version.id, name: project.default_version.name) if project.default_version
            api.default_assignee(id: project.project.default_assigned_to.id, name: project.project.default_assigned_to.name) if project.default_assigned_to

            render_api_custom_values(project.visible_custom_field_values, api)

            api.created_on(project.created_on)
            api.updated_on(project.updated_on)
            api.start_date(project.start_date)
            api.due_date(project.due_date)

            api.scheduled_for_destroy(project.scheduled_for_destroy?)
            api.destroy_at(project.destroy_at) if project.scheduled_for_destroy?

            api.array :trackers do
              project.trackers.each do |tracker|
                api.tracker(:id => tracker.id, :name => tracker.name, :internal_name => tracker.internal_name, :easy_external_id => tracker.easy_external_id)
              end
            end if include_in_api_response?('trackers')

            api.array :issue_categories do
              project.issue_categories.each do |category|
                api.issue_category(:id => category.id, :name => category.name)
              end
            end if include_in_api_response?('issue_categories')

            api.array :time_entry_activities do
              project.activities.each do |activity|
                api.time_entry_activity(:id => activity.id, :name => activity.name)
              end
            end if include_in_api_response?('time_entry_activities')

            api.array :enabled_modules do
              project.enabled_modules.each do |enabled_module|
                api.enabled_module(:id => enabled_module.id, :name => enabled_module.name)
              end
            end if include_in_api_response?('enabled_modules')
          end
        end

        def add_non_filtered_projects(options = {})
          if @query && @projects #&& !apply_sort?(@query)
            ancestors           = []
            ancestor_conditions = @projects.collect { |project| "(#{Project.table_name}.lft < #{project.lft} AND #{Project.table_name}.rgt > #{project.rgt})" }
            if ancestor_conditions.any?
              ancestor_conditions = "(#{ancestor_conditions.join(' OR ')})  AND (projects.id NOT IN (#{@projects.collect(&:id).join(',')}))"
              ancestor_conditions << " AND #{Project.table_name}.parent_id IS NOT NULL" if options[:exclude_roots]
              ancestors = Project.where(ancestor_conditions)
            end

            ancestors.each do |p|
              p.nofilter = ' nofilter'
            end
            @projects << ancestors
            if @query.grouped?
              @projects = @projects.flatten.uniq.sort_by { |i| @query.group_by_column.name.to_s }
            else
              @projects = @projects.flatten.uniq.sort_by(&:lft)
            end
          end
        end

        # EXPORT CSV
        def projects_to_csv(projects, query)
          columns = []
          query.columns.each do |column|
            if column.name == :name && !query.grouped?
              columns << EasyQueryColumn.new(:family_name, sortable: "#{Project.table_name}.name", caption: :field_name)
            else
              columns << column
            end
          end

          # old Export to csv
          if projects.is_a?(Array) && !apply_sort?(query)
            projects = projects.sort_by(&:lft)
          end

          export_to_csv(projects, query, { columns: columns })
        end

        # EXPORT PDF
        def projects_to_pdf(projects, query)
          pdf = ITCPDF.new(current_language)
          pdf.SetTitle(l(:label_project_plural))
          pdf.alias_nb_pages
          pdf.footer_date = format_date(Date.today)
          pdf.AddPage("C")

          # title
          pdf.SetFontStyle('B', 11)
          pdf.RDMCell(190, 10, l(:label_project_plural))
          pdf.Ln

          row_height = 5

          col_width = Array.new

          query.columns.each do |column|
            case column.name
            when :status
              col_width << 0.5
            when :family_name, :name
              col_width << 1.5
            when :description
              col_width << 2
            else
              col_width << 0.7
            end
          end
          ratio     = 262.0 / col_width.inject(0) { |s, w| s += w }
          col_width = col_width.collect { |w| w * ratio }

          # headers
          pdf.SetFontStyle('B', 8)
          pdf.SetFillColor(230, 230, 230)
          columns = Array.new
          query.columns.each do |column|
            if column.name == :name && !query.grouped?
              columns << EasyQueryColumn.new(:family_name, :sortable => "#{Project.table_name}.name")
            else
              columns << column
            end
            pdf.RDMCell(col_width[query.columns.index(column)], row_height, column.caption.to_s, 1, 0, 'L', 1)
          end
          pdf.Ln

          #rows
          pdf.SetFontStyle('', 8)
          pdf.SetFillColor(255, 255, 255)

          projects_list = Array.new
          if apply_sort?(query) || query.grouped?
            projects_list = projects
          else
            projects_list = projects.sort_by(&:lft)
          end
          previous_group = false
          projects_list.each do |project|
            # group_by option
            if query.grouped? && (group = query.group_by_column.value(project)) != previous_group
              pdf.SetFontStyle('B', 9)
              pdf.RDMCell(262, row_height,
                          (group.blank? ? 'None' : group.to_s) + " (#{query.entity_count_by_group[group]})",
                          1, 1, 'L')
              pdf.SetFontStyle('', 8)
              previous_group = group
            end

            col_values = Array.new
            columns.each do |column|
              if column.name == :family_name && !query.grouped?
                col_values << project.family_name(:self_only => true, :prefix => ' ', :separator => ' ')
              else
                col_values << format_value_for_export(project, column)
              end
            end

            # Find biggest cell - his height<int>
            max_height = get_max_cell_height(columns, col_values, col_width) * row_height

            base_x = pdf.GetX
            base_y = pdf.GetY
            # make new page if it doesn't fit on the current one
            space_left = pdf.GetPageHeight - base_y - pdf.GetBreakMargin();
            if max_height > space_left
              pdf.AddPage('C')
              base_x = pdf.GetX
              base_y = pdf.GetY
              pdf.Line(base_y, base_y, col_width.sum, base_y)
            end

            columns.each_with_index do |column, i|
              pdf.SetFontStyle('', 8)
              if column.name == :family_name && !query.grouped?
                pdf.SetFontStyle('B', 7) if !project.child? && !apply_sort?(query)
                pdf.SetFontStyle('BI', 7) if project.css_project_classes.include?(' nofilter')
                pdf.RDMMultiCell(col_width[i], row_height, col_values[i], 0, 'L', 0, 0)
              else
                pdf.RDMMultiCell(col_width[i], row_height, col_values[i], 0, 'L', 0, 0)
              end
            end
            projects_to_pdf_draw_borders(pdf, base_x, base_y, base_y + max_height, col_width)
            pdf.Ln(max_height)
          end

          pdf.Output
        end

        # Draw lines to close the row (MultiCell border drawing in not uniform)
        def projects_to_pdf_draw_borders(pdf, top_x, top_y, lower_y, col_widths)
          col_x = top_x
          col_widths.each do |width|
            col_x += width
            pdf.Line(col_x, top_y, col_x, lower_y) # columns right border
          end
          pdf.Line(top_x, top_y, top_x, lower_y) # left border
          pdf.Line(top_x, lower_y, col_x, lower_y) # bottom border
        end

        def get_max_cell_height(columns, col_values, col_width)
          tmp_pdf = ITCPDF.new(current_language)
          tmp_pdf.SetTitle(l(:label_project_plural))
          tmp_pdf.alias_nb_pages
          tmp_pdf.footer_date = format_date(Date.today)
          tmp_pdf.AddPage("C")
          tmp_pdf.SetFontStyle('', 8)
          tmp_pdf.SetFillColor(255, 255, 255)
          max_height = 1
          base_y     = tmp_pdf.GetY

          columns.each_with_index do |column, i|
            col_x = tmp_pdf.GetX
            tmp_pdf.RDMMultiCell(col_width[i], 1, col_values[i], 1, 'L', 0, 1)
            max_height = (tmp_pdf.GetY - base_y) if (tmp_pdf.GetY - base_y) > max_height
            tmp_pdf.SetXY(col_x + col_width[i], base_y);
          end

          return max_height
        end

        def apply_sort?(query)
          if (!query.sort_criteria.nil? && query.sort_criteria.size > 0)
            return true
          else
            return false
          end
        end

        def add_parent_project_to_projects_collection(projects, query)
          if !apply_sort?(query)
            final_projects_collection = []
            projects.each do |p|
              if (p.child? && !projects.include?(p.parent))
                parent          = p.parent
                parent.nofilter = " nofilter"
                final_projects_collection << parent
                final_projects_collection << p
              else
                final_projects_collection << p
              end
            end
            projects = final_projects_collection.flatten.uniq.sort_by(&:lft)
          end
          return projects
        end

        def easy_version_query_additional_query_buttons(entity, options = {})
          entity.css_shared = 'shared' if entity.project != @project
          s                 = ''
          s << link_to_if_authorized(l(:button_edit), { :controller => 'versions', :action => 'edit', :id => entity }, :class => 'icon icon-edit').to_s
          s << link_to_if_authorized(l(:button_delete), { :controller => 'versions', :action => 'destroy', :id => entity }, :data => { :confirm => l(:text_are_you_sure) }, :method => :delete, :class => 'icon icon-del').to_s
          s.html_safe
        end

        def options_for_default_project_page(enabled_modules, selected = nil)
          default_pages = []

          default_pages << 'project_overview'
          default_pages << 'roadmap'
          unless enabled_modules.blank?
            default_pages << 'issue_tracking' if enabled_modules.include?('issue_tracking') && !EasyExtensions::EasyProjectSettings.disabled_features[:modules].include?('issue_tracking')
            default_pages << 'time_tracking' if enabled_modules.include?('time_tracking') && !EasyExtensions::EasyProjectSettings.disabled_features[:modules].include?('time_tracking')
            default_pages << 'news' if enabled_modules.include?('news') && !EasyExtensions::EasyProjectSettings.disabled_features[:modules].include?('news')
            default_pages << 'documents' if enabled_modules.include?('documents') && !EasyExtensions::EasyProjectSettings.disabled_features[:modules].include?('documents')
            default_pages << 'repository' if enabled_modules.include?('repository') && !EasyExtensions::EasyProjectSettings.disabled_features[:modules].include?('repository')
            default_pages << 'boards' if enabled_modules.include?('boards') && !EasyExtensions::EasyProjectSettings.disabled_features[:modules].include?('boards')
            default_pages << 'files' if enabled_modules.include?('files') && !EasyExtensions::EasyProjectSettings.disabled_features[:modules].include?('files')
            default_pages << 'wiki' if enabled_modules.include?('wiki') && !EasyExtensions::EasyProjectSettings.disabled_features[:modules].include?('wiki')
            default_pages << 'calendar' if enabled_modules.include?('calendar') && !EasyExtensions::EasyProjectSettings.disabled_features[:modules].include?('calendar')
            default_pages << 'gantt' if enabled_modules.include?('gantt') && !EasyExtensions::EasyProjectSettings.disabled_features[:modules].include?('gantt')
          end

          call_hook(:helper_options_for_default_project_page, :default_pages => default_pages, :enabled_modules => enabled_modules)

          selected ||= 'project_overview'

          options_for_select(default_pages.collect { |x| [l(:"project_default_page.#{x.to_s}"), x.to_s] }, selected)
        end

        def project_assignable_users_collection(project, options = {})
          assignable        = project.assignable_users.group_by(&:type)
          options[:show_me] = true if !options.key?(:show_me)

          users_and_groups = []
          unless assignable["User"].blank?
            users = []
            users << ["<< #{l(:label_nobody)} >>".html_safe, '__nobody__'] if options[:show_nobody]
            users << ["<< #{l(:label_no_change)} >>".html_safe, '__no_change__'] if options[:show_no_change]
            users << ["<< #{l(:label_me)} >>".html_safe, User.current.id] if options[:show_me] && assignable.value?(User.current)
            users << ["<< #{l(:label_me)} >>".html_safe, '__me__'] if !options[:show_me] && options[:show_me_substitute]
            users << [l(:label_author_assigned_to), '__author__'] if options[:show_author]
            users << [l(:label_last_user_assigned_to), '__last_assigned_to__'] if options[:last_assigned_to]
            users += assignable["User"].collect { |u| [u.name, u.id] }

            users_and_groups << [l(:label_issue_assigned_to_users), users]
          end

          users_and_groups << [l(:label_issue_assigned_to_groups), assignable["Group"].collect { |u| [u.name, u.id] }] unless assignable["Group"].blank?

          users_and_groups
        end

        def project_named_status(project)
          case project.status
          when Project::STATUS_PLANNED
            l(:project_status_planned)
          when Project::STATUS_ACTIVE
            l(:project_status_active)
          when Project::STATUS_CLOSED
            l(:project_status_closed)
          when Project::STATUS_ARCHIVED
            l(:project_status_archived)
          end
        end

      end
    end

    module InstanceMethods
      def project_settings_tabs_with_easy_extensions(options = {})
        tabs = [
            { :name => 'modules', :action => :select_project_modules, :partial => 'projects/settings/modules', :label => :label_module_plural, :no_js_link => true },
            { :name => 'members', :action => :manage_members, :partial => 'projects/settings/members', :label => :label_member_plural, :no_js_link => true },
        ]
        tabs << { :name => 'versions', :action => :manage_versions, :partial => 'projects/settings/versions', :label => :label_version_plural, :no_js_link => true } if @project.module_enabled?(:issue_tracking)
        tabs << { :name => 'categories', :action => :manage_categories, :partial => 'projects/settings/issue_categories', :label => :label_issue_category_plural, :no_js_link => true } if @project.display_issue_categories?
        tabs << { :name => 'repositories', :action => :manage_repository, :partial => 'projects/settings/repositories', :label => :label_repository, :no_js_link => true } if @project.module_enabled?(:repository)
        tabs << { :name => 'boards', :action => :manage_boards, :partial => 'projects/settings/boards', :label => :label_board_plural, :no_js_link => true } if @project.module_enabled?(:boards)
        tabs << { :name => 'activities', :action => :manage_project_activities, :partial => 'projects/settings/activities', :label => :enumeration_activities, :no_js_link => true } if @project.module_enabled?(:time_tracking)
        tabs << { :name => 'easy_issue_timer', :action => :manage_easy_issue_timers, :partial => 'projects/settings/easy_issue_timer_settings', :label => :label_easy_issue_timer_settings, :no_js_link => true } if @project.module_enabled?(:issue_tracking)

        tabs.select! { |tab| User.current.allowed_to?(tab[:action], @project) }
        if @project.editable?
          tabs.prepend({ :name => 'history', :action => :history, :partial => 'projects/settings/history', :label => :label_history, :no_js_link => true })
          tabs.prepend({ :name => 'info', :action => :edit_project, :partial => 'projects/edit', :label => :label_information_plural, :no_js_link => true })
        end

        template = options ? options[:template] : nil
        call_hook(:helper_project_settings_tabs, :project => @project, :tabs => tabs, :template => template)

        return tabs
      end

      # Returns allowed parent depends on project
      # => options:
      # =>    :force => :projects or :templates
      def parent_project_select_tag_with_easy_extensions(project, options = {})
        options        ||= {}
        options[:html] ||= {}
        selected       = project.parent
        if options[:force] == :projects && selected && selected.easy_is_easy_template?
          selected = nil
        end
        # retrieve the requested parent project
        parent_id = (params[:project] && params[:project][:parent_id]) || params[:parent_id]
        if parent_id
          selected = (parent_id.blank? ? nil : Project.find(parent_id))
        end

        html_name = options[:html].delete(:name) || 'project[parent_id]'
        html_id   = options[:html].delete(:id) || 'project_parent_id'

        if project.allowed_parents_scope(nil, options).count > EasySetting.value('easy_select_limit').to_i
          selected_value = { :id => selected.id, :name => selected.name } if selected
          selected_value ||= { :id => '', :name => '' }
          easy_autocomplete_tag(html_name,
                                selected_value,
                                load_allowed_parents_projects_path(project,
                                                                   { id: project,
                                                                     force: options.delete(:force),
                                                                     from_template: options[:from_template],
                                                                     format: 'json',
                                                                     nested_autocomplete: options[:nested_autocomplete] }),
                                { html_options: {id: html_id},
                                  root_element: 'projects',
                                  render_item: options[:render_item],
                                  onchange: options[:onchange]})
        else
          select_options = ''
          select_options << "<option value=''>&nbsp;</option>" if project.allowed_parents(nil, options).include?(nil)
          select_options << project_tree_options_for_select(project.allowed_parents(nil, options).compact, :selected => selected)
          content_tag('select', select_options.html_safe, :name => html_name, :id => html_id, :onchange => options[:onchange])
        end
      end

      def easy_project_history_module_tabs(module_data)
        tabs = []
        tabs << { name: 'comments', label: l(:label_comment_plural), trigger: 'EntityTabs.showComments(this)' }
        tabs << { name: 'history', label: l(:label_history), trigger: 'EntityTabs.showHistory(this)', partial: 'easy_page_modules/projects/history_tabs/history', partial_locals: { project: module_data[:project], journals: module_data[:journals] } }

        tabs
      end

      def project_time_entries(project)
        TimeEntry.where(project_id: project)
      end
    end
  end
end
EasyExtensions::PatchManager.register_helper_patch 'ProjectsHelper', 'EasyPatch::ProjectsHelperPatch'
