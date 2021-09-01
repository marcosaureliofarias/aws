module EasyPatch

  module MenuHelperPatch
    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :extract_node_details, :easy_extensions
        alias_method_chain :render_menu, :easy_extensions
        alias_method_chain :render_single_menu_node, :easy_extensions
        alias_method_chain :render_menu_node_with_children, :easy_extensions
        alias_method_chain :menu_items_for, :easy_extensions

        def render_easy_custom_menu(user)
          menus     = user.easy_user_type.easy_custom_menus.group_by(&:root_id)
          root_item = Redmine::MenuManager::MenuNode.new(:root, {})

          init_item = proc do |item|
            EasyMenuItem.new("#{item.id}_#{item.name}", item.url,
                             caption: item.name,
                             html: {
                               class: "#{item.easy_icon} #{'selected' if item.url == request.fullpath}",
                               title: item.name
                             }
            )
          end

          Array(menus[nil]).each do |root|
            menu_item = init_item.call(root)

            Array(menus[root.id]).each do |submenu|
              submenu_item = init_item.call(submenu)
              menu_item.add(submenu_item)
            end

            root_item.add(menu_item)
          end

          root_item.children.collect { |node| render_menu_easy_node(node) }.join("\n").html_safe
        end

        def render_dashboard_menu(menu, project = nil)
          menu_items        = Array.new
          nil_category_name = 'others'
          menu_items_for(menu).group_by { |item| item.html_options[:menu_category] }.each_pair do |category, items|
            lis = Array.new
            items.each do |item|
              lis << render_dashboard_menu_node(item, project)
            end
            menu_items << content_tag(:fieldset, :class => "dashboard-container #{category}") do
              content_tag(:legend, l(category || nil_category_name, :scope => [:dashboard, :legends], :default => h(category))) +
                  content_tag(:ul, lis.join("\n").html_safe, :class => "#{category || nil_category_name} menu-manager")
            end
          end

          return content_tag(:div, menu_items.join.html_safe, :class => 'menu-dashboard', :id => 'menu_' + menu.to_s)
        end

        def render_dashboard_menu_node(node, project = nil)
          caption, url, selected = extract_node_details(node, project)
          return content_tag('li', render_dashboard_menu_node_item(node, caption, url, selected), :class => selected && 'selected' || '')
        end

        def render_dashboard_menu_node_item(item, caption, url, selected)
          link_to(content_tag(:span, content_tag(:i, '', item.html_options.except(:link_options)), class: 'dashboard-item-icon') + content_tag(:span, h(caption), class: 'dashboard-item-label'),
                  url,
                  item.html_options[:link_options])
        end

        def render_easy_menu(menu, project = nil, options = {})
          links = []
          menu_items_for(menu, project) do |node|
            node.project = options[:optional_project]
            links << render_menu_easy_node(node, project)
          end
          if options[:no_container]
            links.join("\n").html_safe
          elsif links.empty?
            nil
          else
            content_tag('ul', links.join("\n").html_safe, :class => "menu-manager menu-#{menu.to_s.dasherize}")
          end
        end

        def render_menu_easy_node(node, project = nil)
          if node.children.present? || !node.child_menus.nil?
            if node.parent.name == :root
              return render_menu_easy_node_with_children(node, project)
            else
              return render_menu_node_with_children(node, project)
            end
          else
            caption, url, selected = extract_node_details(node, project)
            return content_tag('li',
                               render_single_menu_node(node, caption, url, selected))
          end
        end

        def render_menu_easy_node_with_children(node, project = nil)
          caption, url, selected = extract_node_details(node, project)

          html = [].tap do |html|
            html << '<li class="with-easy-submenu">'

            # Parent
            html << render_single_menu_node(node, caption, url, selected)

            html << content_tag(:span, :class => 'easy-top-menu-more-toggler') do
              content_tag(:i, '', :class => 'icon-arrow down')
            end


            # Standard children
            standard_children_list = "".html_safe.tap do |child_html|
              each_node_easy_children(node, project) do |child|
                child_html << render_menu_node(child, project)
              end
            end

            html << content_tag(:ul, standard_children_list, :class => 'menu-children easy-menu-children', :style => 'display:none', :id => "easy_menu_children_#{node.name}") unless standard_children_list.empty?

            # Unattached children
            unattached_children_list = render_unattached_children_menu(node, project)
            html << content_tag(:ul, unattached_children_list, :class => 'menu-children easy-menu-children unattached', :style => 'display:none', :id => "easy_menu_children_#{node.name}") unless unattached_children_list.blank?

            html << '</li>'
          end
          return html.join("\n").html_safe
        end

        def each_node_easy_children(node, entity = nil, &block)
          node.children.each do |child|
            next unless allowed_node?(child, User.current, entity)
            yield child
          end
        end

        def render_easy_custom_project_menu(project)
          return render_menu(:application_menu, project) if project.nil? || project.new_record?
          return render_menu(:project_menu, project) if !project.easy_has_custom_menu?

          all_project_items = Redmine::MenuManager.items(:project_menu).root.children.select { |node| node.allowed?(User.current, project) }

          links = []

          EasyCustomProjectMenu.for_project(project).sorted.each do |custom_item|
            if custom_item.original_item?
              node = all_project_items.detect { |n| n.name.to_s == custom_item.menu_item.to_s }
              links << render_menu_node(node, project) if node
            else
              links << content_tag('li', link_to(custom_item.name, custom_item.url))
            end
          end

          links.empty? ? nil : content_tag('ul', links.join("\n").html_safe)
        end

        #  issue sidebar more menu links
        def link_to_issue_new_time_entry(options = {})
          new_easy_time_entry_path({ issue_id: @issue, back_url: issue_path(@issue), modal: true, format: 'js' }.merge(options))
        end

        def link_to_issue_copy(options = {})
          { :controller => 'issues', :action => 'new', :project_id => @issue.project, :copy_from => @issue }.merge(options)
        end

        def link_to_issue_copy_as_subtask(options = {})
          { :controller => 'issues', :action => 'new', :project_id => @issue.project, :copy_from => @issue, :subtask_for_id => @issue.id, :copy_subtasks => false }.merge(options)
        end

        def link_to_issue_move(options = {})
          { :controller => 'issues', :action => 'bulk_edit', :ids => [@issue] }.merge(options)
        end

        def link_to_issue_new_subtask(options = {})
          { :controller => 'issues', :action => 'new', :project_id => @issue.project, :subtask_for_id => @issue }.merge(options)
        end

        def link_to_issue_new_project(options = {})
          { :controller => 'projects', :action => 'new', :project => { :name => @issue.subject, :description => @issue.description, :due_date => @issue.due_date, :parent_id => @issue.project } }.merge(options)
        end

      end

    end

    module InstanceMethods

      def extract_node_details_with_easy_extensions(node, entity = nil)
        entity  ||= node.project || (node.parent && node.parent.project)
        item    = node
        caption = item.caption(entity)
        url     = case item.url
                  when Hash
                    additional_url_params = item.param.is_a?(Proc) ? (item.param.call(entity) || {}) : {}
                    additional_url_params.merge!((entity.nil? || item.param.is_a?(Proc)) ? item.url : { item.param => entity }.merge(item.url))
                    additional_url_params.merge!(item.url_params)
                  when Symbol
                    if method(item.url).arity == -1
                      send(item.url, item.url_params)
                    else
                      send(item.url)
                    end
                  else
                    item.url
                  end

        return [caption, url, (current_menu_item == item.name)]
      end

      def menu_items_for_with_easy_extensions(menu, project = nil)
        items = []
        Redmine::MenuManager.items(menu).root.children.each do |node|
          if node.allowed?(User.current, project)
            node.menu_name = menu

            if block_given?
              yield node
            else
              items << node # TODO: not used?
            end
          end
        end
        return block_given? ? nil : items
      end

      def render_menu_with_easy_extensions(menu, project = nil)
        links = []
        menu_items_for(menu, project) do |node|
          links << render_menu_node(node, project)
        end
        links.empty? ? nil : content_tag('ul', links.join.html_safe, :class => "menu-manager menu-#{menu.to_s.dasherize}")
      end

      def render_single_menu_node_with_easy_extensions(item, caption, url, selected)
        if (render_partial_path = item.html_options[:render_partial_path])
          render(partial: render_partial_path, locals: { item: item, caption: caption, url: url, selected: selected })
        else
          render_single_menu_node_without_easy_extensions(item, caption, url, selected)
        end
      end

      def render_menu_node_with_children_with_easy_extensions(node, entity = nil)
        caption, url, selected = extract_node_details(node, entity)

        html = [].tap do |html|
          html << '<li>'
          # Parent
          html << render_single_menu_node(node, caption, url, selected)

          # Standard children
          standard_children_list = ''.html_safe.tap do |child_html|
            each_node_easy_children(node, entity) do |child|
              child_html << render_menu_node(child, entity) if allowed_node?(child, User.current, entity)
            end
          end

          html << content_tag(:ul, standard_children_list, :class => 'menu-children') unless standard_children_list.empty?

          # Unattached children
          unattached_children_list = render_unattached_children_menu(node, entity)
          html << content_tag(:ul, unattached_children_list, :class => 'menu-children unattached') unless unattached_children_list.blank?

          html << '</li>'
        end
        return html.join("\n").html_safe
      end

    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_other_patch 'Redmine::MenuManager::MenuHelper', 'EasyPatch::MenuHelperPatch'
