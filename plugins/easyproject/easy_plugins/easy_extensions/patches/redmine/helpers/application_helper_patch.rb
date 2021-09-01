# encoding: utf-8
module EasyPatch
  module ApplicationHelperPatch

    def self.included(base)
      base.include(InstanceMethods)
      base.include(EasyConcerns::EasyPagesHelper)
      base.include(RedmineExtensions::ApplicationHelper)

      base.class_eval do

        alias_method_chain :calendar_for, :easy_extensions
        alias_method_chain :checked_image, :easy_extensions
        alias_method_chain :authorize_for, :easy_extensions
        alias_method_chain :breadcrumb, :easy_extensions
        alias_method_chain :body_css_classes, :easy_extensions
        alias_method_chain :context_menu, :easy_extensions
        alias_method_chain :format_activity_description, :easy_extensions
        alias_method_chain :format_object, :easy_extensions
        alias_method_chain :html_hours, :easy_extensions
        alias_method_chain :include_calendar_headers_tags, :easy_extensions
        alias_method_chain :javascript_heads, :easy_extensions
        alias_method_chain :labelled_fields_for, :easy_extensions
        alias_method_chain :labelled_form_for, :easy_extensions
        alias_method_chain :link_to_attachment, :easy_extensions
        alias_method_chain :link_to_issue, :easy_extensions
        alias_method_chain :link_to_project, :easy_extensions
        alias_method_chain :link_to_user, :easy_extensions
        alias_method_chain :parse_redmine_links, :easy_extensions
        alias_method_chain :parse_headings, :easy_extensions
        alias_method_chain :principals_check_box_tags, :easy_extensions
        alias_method_chain :progress_bar, :easy_extensions
        alias_method_chain :project_tree_options_for_select, :easy_extensions
        alias_method_chain :render_flash_messages, :easy_extensions
        alias_method_chain :render_project_jump_box, :easy_extensions
        alias_method_chain :render_tabs, :easy_extensions
        alias_method_chain :sidebar_content?, :easy_extensions
        alias_method_chain :stylesheet_link_tag, :easy_extensions
        alias_method_chain :thumbnail_tag, :easy_extensions
        alias_method_chain :title, :easy_extensions
        alias_method_chain :toggle_link, :easy_extensions

        const_set(:EASY_STYLES_RE, /style="[^"]+ #[^"]+"/)

        class << self
          def define_easy_links_re
            ApplicationHelper.const_set(:EASY_LINKS_RE,
                                        %r{
            <a( [^>]+?)?>(?<tag_content>.*?)</a>|
            (?<leading>[\s\(,\-\[\>]|^)
            (?<esc>!)?
            (?<project_prefix>(?<project_identifier>[a-z0-9\-_]+):)?
            (?<prefix>#{redmine_links_allowed_prefixes.join('|')})?
            (
              (
                (?<sep1>\#\#?)|
                (
                  (?<repo_prefix>(?<repo_identifier>[a-z0-9\-_]+)\|)?
                  (?<sep2>r)
                )
              )
              (
                (?<identifier1>\d+)
                (?<comment_suffix>
                  (\#note)?
                  -(?<comment_id>\d+)
                )?
              )|
              (
              (?<sep3>:)
              (?<identifier2>[^"\s<>][^\s<>]*?|"[^"]+?")
              )|
              (
              (?<sep4>@)
              (?<identifier3>[A-Za-z0-9_\-@\.]*)
              )
            )
            (?=
              (?=[[:punct:]][^A-Za-z0-9_/])|
              ,|
              \s|
              &nbsp;|
              \]|
              <|
              $)
              }x)
          end

          def redmine_links_allowed_prefixes
            %w(attachment document version forum news message project commit source export user)
          end
        end

        def apply_template_base_link(page_id, url_options = {})
          opts = { back_url: back_url, page_id: page_id }.merge(url_options)

          link_to l('notice_apply_template.apply_template'), easy_page_layout_layout_from_template_add_replace_path(opts), remote: true, class: 'icon icon-bulb button'
        end

        # Translate entity
        #
        #  entity_translated_name(Issue.first)
        #  # => "Task"
        #
        #  entity_translated_name(Issue)
        #  # => "Task"
        #
        #  entity_translated_name(Issue, pluralize: true)
        #  # => "Tasks"
        #
        # @param entity [Class, ActiveRecord::Base]
        # @param pluralize [true, false]
        #
        def entity_translated_name(entity, pluralize: false)
          if !entity.is_a?(Class)
            entity = entity.class
          end

          name = entity.name.downcase

          if pluralize
            main_key = "label_#{name.pluralize}"
            default  = [
                "label_#{name}_plural".to_sym,
                entity.name.pluralize
            ]
          else
            main_key = "label_#{name}"
            default  = [entity.name]
          end

          l(main_key, default: default)
        end

        def link_to_remote(name, options = {}, html_options = nil)
          ActiveSupport::Deprecation.warn('link_to_remote is deprecated! user link_to :remote => true !!!')
          link_to_function(name, remote_function(options), html_options || options.delete(:html))
        end

        def remote_function(options)
          ActiveSupport::Deprecation.warn('remote_function is deprecated!!!!')
          javascript_options = options_for_ajax(options)

          #          update = ''
          #          if options[:update] && options[:update].is_a?(Hash)
          #            update  = []
          #            update << "success:'#{options[:update][:success]}'" if options[:update][:success]
          #            update << "failure:'#{options[:update][:failure]}'" if options[:update][:failure]
          #            update  = '{' + update.join(',') + '}'
          #          elsif options[:update]
          #            update << "'#{options[:update]}'"
          #          end
          #
          #          function = update.empty? ?
          #            "new Ajax.Request(" :
          #            "new Ajax.Updater(#{update}, "

          function = "$.ajax({url:"

          url_options = options[:url]
          function << "'#{html_escape(j(url_for(url_options)))}'"
          function << ", #{javascript_options}" if javascript_options.present?
          function << '})'
          function << ".done(function() {#{options[:complete]}})" if options[:complete]
          function << ".always(function(data) {$('##{options[:update]}').html(data)})" if options[:update].is_a? String

          function = "#{options[:before]}; #{function}" if options[:before]
          function = "#{function}; #{options[:after]}" if options[:after]
          function = "if (#{options[:condition]}) { #{function}; }" if options[:condition]
          function = "if (confirm('#{j(options[:confirm])}')) { #{function}; }" if options[:confirm]

          return function.html_safe
        end

        def options_for_ajax(options)
          js_options = {}

          js_options['async'] = options[:type] != :synchronous
          js_options['type']  = options[:method].to_s if options[:method]

          ActiveSupport::Deprecation.warn('options_for_ajax: options[:position] is deprecated!') if options[:position]
          ActiveSupport::Deprecation.warn('options_for_ajax: options[:script] is deprecated!') if options[:script]
          #          js_options['insertion']    = "'#{options[:position].to_s.downcase}'" if options[:position]
          #          js_options['evalScripts']  = options[:script].nil? || options[:script]

          if options[:form]
            js_options['data'] = 'this.form.serialize()'
          elsif options[:submit]
            js_options['data'] = "$('##{options[:submit]}).serialize()'"
          elsif options[:with]
            js_options['data'] = options[:with]
          end

          #          if protect_against_forgery? && !options[:form]
          #            if js_options['parameters']
          #              js_options['parameters'] << " + '&"
          #            else
          #              js_options['parameters'] = "'"
          #            end
          #            js_options['parameters'] << "#{request_forgery_protection_token}=' + encodeURIComponent('#{j form_authenticity_token}')"
          #          end

          return "#{js_options.keys.map { |k| "#{k}:#{js_options[k]}" }.sort.join(', ')}"
        end

        def easy_stylesheet_link_tag(*sources)
          @easy_stylesheet_link_tags ||= Hash.new { |hash, key| hash[key] = Array.new }
          # :default => 'plugin_assets/easy_default_cache_css'
          # @easy_stylesheet_link_tags ||= Hash.new { |hash, key| hash[key] = Hash.new }
          options = sources.extract_options!

          if sources.empty?
            links = ''
            # @easy_stylesheet_link_tags.sort_by{|k,v| v[:position]}.each do |k,v|
            #   next if v[:files].empty?
            #   links << stylesheet_link_tag(*(v[:files].compact+[{:cache => k, :media => 'all'}]))
            # end
            @easy_stylesheet_link_tags.each do |plugin, h_sources|
              h_sources.each do |source|
                links << stylesheet_link_tag(source, { :plugin => plugin })
              end
            end

            return links.html_safe
          else
            # plugin = options.delete(:plugin)
            # use_cache = options.delete(:cache_file) || "easy_default_cached_css#{current_theme && current_theme.dir}"
            # use_cache_in = options.delete(:cache_path) || 'plugin_assets/easy_extensions/stylesheets'

            # cache_key = options.delete(:cache_key) || File.join('/', use_cache_in, use_cache)

            # @easy_stylesheet_link_tags[cache_key][:files] ||= Array.new
            # @easy_stylesheet_link_tags[cache_key][:position] = options[:position] if options[:position]
            # @easy_stylesheet_link_tags[cache_key][:position] ||= @easy_stylesheet_link_tags.keys.size

            sources.each do |source|
              @easy_stylesheet_link_tags[options[:plugin]] << source
              # if plugin
              #   css_source = "/plugin_assets/#{plugin}/stylesheets/#{source}"
              # else
              #   css_source = source
              # end

              # unless @easy_stylesheet_link_tags[cache_key][:files].include?(css_source)

              #   if options[:position_file_at] && @easy_stylesheet_link_tags[cache_key][:files].count >= options[:position_file_at]
              #     @easy_stylesheet_link_tags[cache_key][:files].insert(options[:position_file_at], css_source)
              #   else
              #     @easy_stylesheet_link_tags[cache_key][:files] << css_source
              #   end
              # end
            end

          end
        end

        def easy_simple_format(text, options = {})
          text = h(text.to_s)
          if options.delete(:truncate)
            text = truncate_at_line_break(text)
          end
          if Setting.text_formatting == 'HTML'
            text = simple_format_without_paragraph(text)
          end
          text
        end

        def easy_javascript_include_tag(*sources)
          @easy_javascript_include_tags ||= ActiveSupport::OrderedHash.new { |hash, key| hash[key] = Array.new }
          # @easy_javascript_include_tags ||= []
          options = sources.extract_options!

          if sources.empty?
            scripts = ''
            @easy_javascript_include_tags.each do |plugin, j_sources|
              j_sources.each do |source|
                scripts << javascript_include_tag(source, { :plugin => plugin })
              end
            end
            #javascript_include_tag(*(@easy_javascript_include_tags + [{:cache => '/plugin_assets/easy_extensions/javascripts/js_all'}]))
            return scripts.html_safe
          else
            plugin = options.delete(:plugin)

            sources.each do |source|
              # if plugin
              #   js_source=  "/plugin_assets/#{plugin}/javascripts/#{source}"
              # else
              #   js_source = source
              # end
              #@easy_javascript_include_tags << js_source unless @easy_javascript_include_tags.include?(js_source)
              @easy_javascript_include_tags[plugin] << source
            end

          end
        end

        def easy_favicon_tag(options = {})
          options[:source] ||= 'favicon/favicon.ico' unless options[:href]
          options[:href]   ||= asset_path(options.delete(:source) || '')

          tag("link", {
              rel:  "shortcut icon",
              type: "image/x-icon",
              href: options.delete(:href)
          }.merge!(options))
        end

        def easy_favicon
          if EasySetting.value(:ui_theme).presence
            favicon_link_tag 'favicons/er_favicon.ico', rel: 'apple-touch-icon', type: 'image/x-icon'
          else
            favicon_link_tag 'favicon.ico', rel: 'apple-touch-icon', type: 'image/x-icon'
          end
        end

        def easy_favicon_android
          if EasySetting.value(:ui_theme).presence
            favicon_link_tag 'favicons/er_android-icon-192x192.png', rel: 'icon', sizes: '192x192'
          else
            favicon_link_tag 'favicons/android-icon-192x192.png', rel: 'icon', sizes: '192x192'
          end
        end

        def easy_favicon_apple
          if EasySetting.value(:ui_theme).presence
            favicon_link_tag 'favicons/er_apple-icon-precomposed.png', rel: 'apple-touch-icon', type: 'image/x-icon'
          else
            favicon_link_tag 'favicons/apple-icon-precomposed.png', rel: 'apple-touch-icon', type: 'image/x-icon'
          end

        end

        def easy_theme_tag(options = {})
          stylesheet_link_tag(options.delete(:theme_file) || 'easy_theme', options)
        end

        def hh(text)
          text.is_a?(Symbol) ? l(text) : h(text)
        end

        def hour_to_string(hour)
          hour > 9 ? hour.to_s.html_safe : ('0' + hour.to_s).html_safe
        end

        def min_to_string(min)
          min > 9 ? (min.to_s.html_safe) : ('0' + min.to_s).html_safe
        end

        # Cheap knock off of the tabular form builder's labeling
        def label_for_field(field, options = {})
          return ''.html_safe if options.delete(:no_label)
          text = options[:label].is_a?(Symbol) ? l(options[:label]) : options[:label]
          text ||= @object.class.human_attribute_name(field) if @object && @object.class.respond_to?(:human_attribute_name)
          text ||= l(('field_' << field.to_s.gsub(/\_id$/, '')).to_sym)

          additional_classes = []
          additional_classes << 'error' if @object && @object.errors[field].present?

          if options.delete(:required)
            text += content_tag(:span, ' *', :class => 'required')
            additional_classes << 'required'
          end

          if options.key?(:class)
            additional_classes << options.delete(:class)
          end

          additional_for = '_'
          if options.key?(:additional_for)
            additional_for += options.delete(:additional_for).to_s + '_'
          end

          content_tag(:label, text.html_safe,
                      :class => additional_classes.join(' '),
                      :for   => (@object_name.to_s + additional_for + field.to_s)).html_safe
        end

        def datetime_tag(time, options = {})
          text = format_time(time)
          if @project
            link_to(text, { :controller => 'activities', :action => 'index', :id => @project, :from => time.to_date, :only_path => (options[:only_path].nil? ? true : options[:only_path]) }, :title => format_time(time)).html_safe
          else
            content_tag('acronym', text, :title => format_time(time)).html_safe
          end
        end

        def project_tree_select(projects, options = {})
          return ''.html_safe if projects.empty?

          for_select, for_options = options.dup, options.dup
          for_select.delete(:include_blank)
          for_select.delete(:prompt)
          for_options.delete(:data)

          select_tag(for_select[:name], project_tree_options_for_select(projects, for_options).html_safe, for_select)
        end

        def easy_reorder_links(name, url, options = {})
          (
          link_to("", url.merge("#{name}[move_to]" => 'highest'), { :class => 'icon icon-download move-to-top', :title => l(:label_sort_highest) }.merge(options)) +
              link_to("", url.merge("#{name}[move_to]" => 'higher'), { :class => 'icon icon-arrow-up-bold', :title => l(:label_sort_higher) }.merge(options)) +
              link_to("", url.merge("#{name}[move_to]" => 'lower'), { :class => 'icon icon-arrow-down-bold', :title => l(:label_sort_lower) }.merge(options)) +
              link_to("", url.merge("#{name}[move_to]" => 'lowest'), { :class => 'icon icon-download', :title => l(:label_sort_lowest) }.merge(options))
          ).html_safe
        end

        def entity_tree_options_for_select(entities, options = {})
          s = ''
          entities.sort_by(&:lft).each do |entity|
            name_prefix    = (entity.level > 0 ? ('&nbsp;' * 2 * entity.level + '&#187; ') : '')
            selected_value = entity

            if (options[:selected].is_a?(Array) && options[:selected].size > 0)
              first_item     = options[:selected].first
              selected_value = (first_item.is_a?(String) ? entity.id.to_s : entity.id) if first_item.class != entity.class
            elsif (!options[:selected].blank? && !options[:selected].is_a?(Array))
              if (options[:selected].is_a?(String))
                if (options[:selected].to_i == entity.id)
                  selected_value = options[:selected]
                end
              else
                if (options[:selected].id == entity.id)
                  selected_value = options[:selected]
                end
              end
            end

            tag_options = { :value => entity.id, :selected => (option_value_selected?(selected_value, options[:selected]) ? 'selected' : nil) }
            tag_options.merge!(yield(entity)) if block_given?
            s << content_tag('option', name_prefix + h(entity.to_s), tag_options)
          end
          s.html_safe
        end

        def principals_options_for_autocomplete(collection, default_category = {}, entity = nil)
          json_hash = { users: [] }
          assignables_by_category = collection.group_by { |x| l("label_#{x.model_name.name == 'Group' ? 'group' : 'user'}_plural") }.merge(default_category)

          call_hook :application_helper_principals_options_for_autocomplete_collection, assignables: assignables_by_category, entity: entity

          assignables_by_category.reverse_each do |(category, principals)|
            autocomplete_items = principals.first(EasySetting.value('easy_select_limit').to_i).map {|principal| { value: principal.name, id: principal.id, category: category } }
            call_hook :application_helper_principals_options_for_autocomplete_items, category: category, principals: principals, autocomplete_items: autocomplete_items, entity: entity
            json_hash[:users] += autocomplete_items
          end
          if json_hash[:users].reject{ |user| user[:category] == '' }.one?
            json_hash[:users].each { |user| user[:category] = '' }
          end
          json_hash
        end

        def hourstimecheck_collection_for_select_options(selected, options = {})
          collection = []
          collection << options[:first_option] if options[:first_option]

          24.times do |hour|
            4.times do |minute|
              value = hour_to_string(hour) + ':' + min_to_string(minute * 15)
              collection << [value, value]
            end
          end

          if options[:include_24]
            value = hour_to_string(24) + ':' + min_to_string(0)
            collection << [value, value]
          end

          options_for_select(collection, selected)
        end

        # status_bar([predicted_costs, sum_of_costs])
        def status_bar(pcts, options = {})
          done = 0
          if (pcts[0] == 0.0)
            done = ((pcts[1] == 0.0) ? 0 : -100)
          else
            done = ((pcts[1] / pcts[0]) * 100).round
          end

          options[:legend]         = done.to_s + '%' unless options[:legend]
          options[:progress_class] = "overdrawn" if done < 0

          if (pcts[0] < pcts[1])
            done = done - 100
          end

          done = 100 if (done < 0)

          progress_bar(done, options)
        end

        def project_plus_button(has_children, element_id, uniq_prefix, user = nil)
          user ||= User.current
          html = ""
          html << '<span '
          html << 'class="expander-root project-parent-expander" ' if has_children
          html << "onclick=\"EASY.utils.toggleTableRowVisibility('#{uniq_prefix}', 'project', '#{element_id}', '#{user.id}', true);\" alt='Expander' title='#{l(:collapse_expand)}'></span>"
          html.html_safe
        end

        def project_parent_plus_button(project_id, uniq_prefix, open = false)
          content_tag(:span, '', :class => "expander project-parent-expander#{open ? ' open' : ''}", :data => { :id => project_id, :prefix => uniq_prefix })
        end

        def filter_plus_button(is_group_blank, colspan, uniq_id, content, additional_tags, user = nil, options = {})
          user ||= User.current
          html = ""
          html << "<tr class='group #{'open' if toggle_button_expanded?(uniq_id, user, options[:default].nil? ? true : options[:default])} #{'preloaded' if options[:preloaded]}' id='#{uniq_id }' data-group-name='#{options[:name]}'>"
          html << "<td class='checkbox hide-when-print'>"
          html << "<div class='row-control'><span class='expander' alt='Expander' title='#{l(:collapse_expand)}'></span></div>"
          html << "</td><td colspan='#{colspan - 1}' class='group-name'>"
          if is_group_blank
            html << "#{t(:label_none)}"
          else
            html << content if content
          end
          Array(additional_tags).each do |info|
            html << content_tag(:span, raw(info), :class => 'count badge')
          end
          html << '</td></tr>'

          html.html_safe
        end

        # options:
        # => options[:heading] = text beside of plus button
        # => options[:container_html] = a hash of html attributes
        # => options[:default_button_state] = (true => expanded -), (false => collapsed +)
        # => options[:ajax_call] = make ajax call for saving state (true => ajax call, false => no call, no save)
        # => options[:wrapping_heading_element] = html element outside heading => h3, h4
        def toggling_container(container_uniq_id, user = nil, options = {}, &block)
          user                           ||= User.current
          options[:heading]              ||= ''
          options[:heading_links]        ||= []
          options[:heading_links]        = [options[:heading_links]] if options[:heading_links] && !options[:heading_links].is_a?(Array)
          options[:container_html]       ||= {}
          options[:default_button_state] ||= false if is_mobile_device?
          options[:default_button_state] = true if options[:default_button_state].nil?
          options[:ajax_call]            = true if options[:ajax_call].nil?

          s = ''
          if !options.key?(:no_heading_button)
            options[:heading] = "<span class='module-heading-title' title='#{options[:heading_title]}'>#{options[:heading]}</span>"
            options[:heading] << content_tag(:div, options[:heading_links].join(' ').html_safe, :class => 'module-heading-links') unless options[:heading_links].blank?
            s << module_minus_button(user, options[:heading].html_safe, container_uniq_id, options)
          end
          style = if options[:no_expander]
                    true
                  elsif options[:ajax_call] == false
                    options[:default_button_state]
                  else
                    toggle_button_expanded?(container_uniq_id, user, options[:default_button_state])
                  end
          s << (content_tag(:div, {
              :id    => container_uniq_id,
              :style => (style ? '' : 'display:none'),
              :class => 'module-content'
          }.merge(options[:container_html]) { |k, o, n| "#{o}; #{n}" }, &block))
          s.html_safe
        end

        def toggling_fieldset(heading, options = {}, &block)
          options[:collapsed]   ||= false
          options[:id]          ||= nil
          s, c                  = '', ''
          s << content_tag(:legend, heading, { :class => options[:legend_class], :onclick => 'EasyToggler.toggle(this.nextSibling)' }) if heading
          s << content_tag(:div, { :style => options[:collapsed] ? 'display: none;' : nil, :id => options[:id] }, &block)
          c << 'collapsible'
          c << ' collapsed' if options[:collapsed]
          c << " #{options[:class]}" if options[:class]
          content_tag(:fieldset, s.html_safe, { :class => c, :data => { :toggle => options[:id] } })
        end

        def page_module_toggling_container(page_module, page_params, container_uniq_id, user = nil, options = {}, &block)
          options                          ||= {}
          options[:heading]                = page_module.module_definition.translated_name if options[:heading].blank?
          options[:heading_links]          ||= []
          options[:container_html]         ||= {}
          options[:container_html][:class] ||= ''
          options[:container_html][:class] << ' module-content'
          options[:wrapping_heading_element_classes] ||= ''
          if options[:edit]
            unless page_params[:modal_edit]
              clone_url = url_for(page_params[:url_clone_module])
              clone_choose_target_tab_url = url_for(controller: page_params[:url_clone_module][:controller], action: :clone_module_choose_target_tab, clone_url: clone_url, uuid: page_module.uuid)
              options[:heading_links] << link_to('', clone_choose_target_tab_url, class: 'icon icon-duplicate', title: l(:text_easy_page_clone_module), remote: true)

              options[:heading_links] << link_to_function('', "PageLayout.removeModuleWithUrl(this, '#{j url_for(page_params[:url_remove_module].merge(:uuid => page_module.uuid.underscore))}', '#{j l(:text_are_you_sure)}')", :class => 'icon icon-del', :title => l(:button_delete))
              options[:heading_links] << link_to('', update_my_page_module_view_path(page_module.uuid, :project_id => page_module.entity_id, :template => page_module.is_a?(EasyPageTemplateModule) ? '1' : '0', :block_name => page_module.module_name, :with_container => true, :back_url => page_params[:back_url], :format => :js), :class => 'icon icon-close', :remote => true, :title => l(:button_close)) if page_params[:inline_edit]
              options[:heading_links] << link_to_function('', "PageLayout.prepareSubmitModules();EASY.modalSelector.selectAllOptions('module_inside_#{page_module.uuid}selected_columns');$('#module_#{page_module.module_name}_form').submit()", :class => 'icon icon-save', :title => l(:button_update)) if page_params[:inline_edit]

              options[:wrapping_heading_element_classes] << ' handle' if !page_params[:inline_edit]
            end
          elsif page_module.module_definition.editable? && page_params[:page_editable]
            if page_module.cache_on?
              update_path = update_my_page_module_view_path(page_module.uuid,
                                                            project_id:               page_module.entity_id,
                                                            block_name:               page_module.module_name,
                                                            back_url:                 page_params[:back_url],
                                                            page_module_force_reload: '1',
                                                            with_container:           '1',
                                                            format:                   'js'
              )
              options[:heading_links] << link_to('', update_path, class: 'icon icon-refresh', remote: true, title: l(:label_force_reload))
            end

            if page_module.settings['daily_snapshot'] == '1' && ['list', 'chart'].include?(page_module.settings['outputs'].first)
              outputs = case page_module.settings['outputs']
                        when ['list']
                          ['chart']
                        when ['chart']
                          ['list']
                        end
              options[:heading_links] << link_to('', update_my_page_module_view_path(page_module.uuid, :project_id => page_module.entity_id, :template => page_module.is_a?(EasyPageTemplateModule) ? '1' : '0', with_container: true, :block_name => page_module.module_name, page_module.module_name => {'outputs' => outputs}, :back_url => page_params[:back_url], :format => :js), method: :post, :class => 'icon icon-reload', :remote => true, :title => 'Switch view')
            end
            options[:heading_links] << link_to_function('', "PageLayout.removeModuleWithUrl(this, '#{j url_for(page_params[:url_remove_module].merge(:uuid => page_module.uuid.underscore))}', '#{j l(:text_are_you_sure)}')", :class => 'icon icon-del', :title => l(:button_delete))
            options[:heading_links] << link_to('', update_my_page_module_view_path(page_module.uuid, :project_id => page_module.entity_id, :template => page_module.is_a?(EasyPageTemplateModule) ? '1' : '0', :block_name => page_module.module_name, :modal_edit => true, :back_url => page_params[:back_url], :format => :js), :class => 'icon icon-edit', :remote => true, :title => l(:button_edit))
          end

          toggling_container(container_uniq_id, user, options, &block)
        end

        def new_project_button(*args)
          options = args.extract_options!
          options.reverse_merge!({ class: 'button-positive icon icon-add' })

          if EasyLicenseManager.has_license_limit?(:active_project_limit)
            name = args.shift || l(:label_project_new)
            link = args.shift || new_project_path

            link_to(name, link, options)
          else
            content_tag(:p, class: 'overdrawn') do
              (l('license_manager.project_limit_exceed', limit: EasyLicenseManager.get_active_project_limit) +
                  tag('br') + l('license_manager.project_limit', email: EasyExtensions::EasyProjectSettings.app_email)).html_safe
            end
          end
        end

        def non_ajax_collapsed_toggling_container(container_uniq_id, heading, wrapping_heading_element_classes = '', options = {}, &block)
          options                                    ||= {}
          options[:heading]                          ||= heading
          options[:wrapping_heading_element_classes] ||= wrapping_heading_element_classes
          options[:default_button_state]             = false
          options[:ajax_call]                        = false

          toggling_container(container_uniq_id, User.current, options, &block)
        end

        def toggling_container_string(container_uniq_id, user = nil, options = {}, &block)
          user                           ||= User.current
          options[:heading]              ||= ''
          options[:heading_links]        ||= []
          options[:heading_links]        = [options[:heading_links]] if options[:heading_links] && !options[:heading_links].is_a?(Array)
          options[:container_html]       ||= {}
          options[:default_button_state] = true if options[:default_button_state].nil?
          options[:ajax_call]            = true if options[:ajax_call].nil?

          output_html = ''

          unless options.key?(:no_heading_button)
            options[:heading] << content_tag(:div, options[:heading_links].join(' ').html_safe, :class => 'module-heading-links') unless options[:heading_links].blank?
            output_html << module_minus_button(user, options[:heading], container_uniq_id, { :default => options[:default_button_state], :wrapping_heading_element => options[:wrapping_heading_element], :expander_options => options[:expander_options], :ajax_call => options[:ajax_call] })
          end

          output_html << content_tag(:div, yield.to_s.html_safe, {
              :id    => container_uniq_id,
              :style => (toggle_button_expanded?(container_uniq_id, user, options[:default_button_state]) ? '' : 'display:none')
          }.merge(options[:container_html]))

          output_html.html_safe
        end

        def module_minus_button(user, content, modul_uniq_id, options = {})
          if options[:default_button_state].nil?
            default = true
          else
            default = options[:default_button_state]
          end
          expander_options                 = options[:expander_options] || {}
          wrapping_heading_element         = options[:wrapping_heading_element] || 'h3'
          wrapping_heading_element_classes = (options[:wrapping_heading_element_classes] || '') + ' module-heading'
          wrapping_heading_element_styles  = options[:wrapping_heading_element_styles]
          ajax_call                        = options.delete(:ajax_call) ? 'true' : 'false'

          html = '<div class="module-toggle-button">'
          if options[:no_expander]
            html << content_tag(wrapping_heading_element, content, :class => wrapping_heading_element_classes, :style => wrapping_heading_element_styles)
          else
            html << "<div class='group #{'open' if toggle_button_expanded?(modul_uniq_id, user, default)}' >"
            html << content_tag(wrapping_heading_element, content, :class => wrapping_heading_element_classes, :style => wrapping_heading_element_styles, :onclick => "var target = $((arguments[0] || window.event).target); if( target && !target.hasClass('do_not_toggle') && !target.parent().hasClass('module-heading-links') ) EASY.utils.toggleMyPageModule(this,'#{modul_uniq_id}','#{user.id}', #{ajax_call})")
            html << "<span class='expander #{expander_options[:class]}' onclick=\"EASY.utils.toggleMyPageModule($(this),'#{modul_uniq_id}','#{user.id}', #{ajax_call}); return false;\" id=\"expander_#{modul_uniq_id}\">&nbsp;</span>"
            html << '</div>'
          end
          html << '</div>'

          html.html_safe
        end

        def sidebar_expanded?(uniq_id, default = true)
          return true if Rails.env.test?
          !in_mobile_view? && toggle_button_expanded?(uniq_id, User.current, default)
        end

        # If default = true, then minus(-) is visible, because content is expanded. If default = false then plus(+) is visible, because content is collapsed.
        def toggle_button_expanded?(uniq_id, user = nil, default = true)
          user        ||= User.current
          preferences = user.pref.others.with_indifferent_access
          if preferences["plus_button_status"] && preferences["plus_button_status"].key?(uniq_id)
            show_minus = !preferences["plus_button_status"][uniq_id]
          end
          show_minus = default if show_minus.nil?
          show_minus
        end

        def get_page_module_toggling_container_options(page_module, options = {})
          if (tc_options_method = page_module.module_definition.page_module_toggling_container_options_helper_method) && respond_to?(tc_options_method)
            tc_options = send(tc_options_method, page_module, options)
          else
            tc_options = {}
          end

          tc_options[:no_expander]          = options[:no_expander]
          tc_options[:edit]                 = options[:edit]
          tc_options[:default_button_state] = options[:default_button_state] unless options[:default_button_state].nil?

          if !tc_options[:heading]
            heading = page_module.settings['name'].presence || page_module.settings['heading'].presence
            if options[:edit]
              heading = "#{page_module.module_definition.translated_name}: <span class='small'>#{heading}</span>" if heading
            end
            tc_options[:heading] = content_tag(:span, heading.html_safe) if heading
          end

          if options[:edit]
            query_name                 = page_module.settings['easy_query_type']&.underscore
            tc_options[:heading_title] = l("easy_query.name.#{query_name}") if query_name.present?
          end

          tc_options
        end

        def page_module_settings_text_field_tag(page_module, keys, options = {})
          keys        = Array(keys)
          field_value = options[:value] || page_module.settings.dig(*keys) || options[:default_value]

          if page_module.respond_to?(:translatable_keys) && page_module.translatable_keys.include?(keys)
            options[:class]  ||= ''
            name             = "#{page_module.module_name}#{keys.map { |key| "[#{key}]" }.join}"
            id               = "#{page_module.module_name}_#{keys.join('_')}"
            translation_name = "#{page_module.module_name}[translations]#{keys.map { |key| "[#{key}]" }.join}"
            link             = link_to('', 'javascript:void(0)',
                                       class:   "easy-translation-link icon icon-globe",
                                       title:   l(:button_edit),
                                       onclick: "(function(event) {
                             const url = '#{easy_page_module_translations_index_path(uuid: page_module.uuid, keys: keys, module_class: page_module.class.to_s)}'
                             $.ajax(
                               { url: url,
                                 method: 'post',
                                 data: $(event.target.closest('form')).serialize() }
                             )})(event)")

            disabled = page_module.translations_for_keys(*keys).present?

            content_tag(:span, class: 'input-append') do
              input = content_tag(:input, nil, { class:    'easy-translator-input-field',
                                                 name:     name,
                                                 value:    field_value,
                                                 disabled: disabled,
                                                 type:     'text',
                                                 id:       id }.reverse_merge(options))

              translations = content_tag(:span, id: name + '_translations') do
                translations_inputs = ::ActiveSupport::SafeBuffer.new
                page_module.translations_for_keys(*keys).each do |translation|
                  translations_inputs << hidden_field_tag("#{translation_name}[#{translation[0]}]", translation[1])
                end
                translations_inputs
              end

              hidden = hidden_field_tag(name, page_module.get_original_value_for(*keys))
              input + link + (disabled ? hidden : '') + translations
            end
          else
            name = "#{page_module.module_name}#{keys.map { |key| "[#{key}]" }.join}"
            content_tag(:input, nil, value: field_value, type: 'text', name: name)
          end
        end

        def easy_page_available_modules(easy_page)
          allowed_modules = easy_page.available_modules.inject({}) do |memo, avmod|
            if avmod.module_definition.module_allowed?
              category_key = avmod.module_definition.category_name.underscore

              memo               ||= {}
              memo[category_key] ||= { name: l("easy_pages.module_category.#{category_key}", :default => [avmod.module_definition.category_name, avmod.module_definition.category_name.humanize]), modules: [] }
              memo[category_key][:modules] << avmod
            end
            memo
          end

          return [] if allowed_modules.nil?

          xx = []
          (m = allowed_modules.delete('issues')) && xx << ['issues', m]
          (m = allowed_modules.delete('projects')) && xx << ['projects', m]
          (m = allowed_modules.delete('charts')) && xx << ['charts', m]
          (m = allowed_modules.delete('timelog')) && xx << ['timelog', m]

          others = allowed_modules.delete('others')

          xx.concat(allowed_modules.sort_by { |x, y| y[:name] })

          xx << ['others', others] if !others.nil?
          xx
        end

        def get_epm_easy_query_base_toggling_container_options(page_module, options = {})
          tc_options = {}

          block_name, easy_page_modules_data = options[:block], options[:easy_page_modules_data]
          query                              = easy_page_modules_data[:query] if easy_page_modules_data

          if query
            if !options[:edit]
              presenter = present(query)
              presenter.outputs.first.apply_settings if presenter.outputs.first

              query_name = query.name.to_s
              query_name << " (#{query.entity_count})" if query.display_entity_count?
              if query_path = query.path(outputs: ['list'] | query.outputs)
                heading ||= link_to(query_name, query_path, :title => l(:label_user_saved_query, :queryname => query.name), :target => '_blank', :class => 'do_not_toggle')
              else
                heading ||= query_name
              end

              if page_module.cache_on?
                heading << ' <span class="small">(cached)</span>'.html_safe
              end

              tc_options[:heading]       = heading
              tc_options[:heading_links] = []

              # presenter.outputs.each(:available) do |output|
              #   next unless output.configured?
              #   tc_options[:heading_links] << link_to('', update_my_page_module_view_path(page_module.uuid, :project_id => query.project, :template => page_module.is_a?(EasyPageTemplateModule) ? '1' : '0', :block_name => block_name, block_name.to_s => {'outputs' => [output.key]}, :format => :js), :class => "icon icon-#{output.key}", :remote => true, :title => l(output.key, :scope => [:title_easy_query_change_output]))
              # end
              presenter.outputs.first.restore_settings if presenter.outputs.first
            else
              if page_module.settings[:query_type] == '1'
                query_id         = page_module.settings[:query_id]
                saved_query_name = EasyQuery.where(id: query_id).pluck(:name)
                heading          = saved_query_name.first if saved_query_name.present?
              else
                heading = query.name
              end

              if heading.present?
                heading              = "#{page_module.module_definition.translated_name}: <span class='small'>#{heading}</span>"
                tc_options[:heading] = content_tag(:span, heading.html_safe)
              end
            end

            tc_options[:wrapping_heading_element_classes] = entity_css_icon(query.entity)
          end

          tc_options
        end

        def get_epm_project_news_toggling_container_options(page_module, options = {})
          tc_options = {}
          unless options[:edit]
            epm_data                    = options[:easy_page_modules_data] || {}
            tc_options[:heading_links]  = link_to_if_authorized(l(:label_news_new),
                                                                { :controller => 'news', :action => 'new', :project_id => epm_data[:project] },
                                                                :class => 'icon icon-add') if epm_data[:project]
            tc_options[:container_html] = { :class => 'project-info-news-container' }
          end
          tc_options
        end

        def get_epm_saved_queries_toggling_container_options(page_module, options = {})
          { :wrapping_heading_element_classes => 'icon icon-filter' }
        end

        def get_epm_tag_cloud_toggling_container_options(page_module, options = {})
          epm_title = page_module[:settings]['name'].to_s.presence || l(:label_easy_tags)

          { :heading => epm_title, :wrapping_heading_element_classes => 'icon icon-bookmark' }
        end

        def get_epm_project_sidebar_all_users_queries_toggling_container_options(page_module, options = {})
          { :wrapping_heading_element_classes => 'icon icon-user', :container_html => { :class => 'members' } }
        end

        def get_epm_timelog_simple_toggling_container_options(page_module, options = {})
          tc_options = {}
          unless options[:edit]
            epm_data             = options[:easy_page_modules_data]
            tc_options[:heading] = '<span>'
            tc_options[:heading] << l(:label_spent_time)
            if epm_data
              tc_options[:heading] << ' '
              tc_options[:heading] << content_tag(:span, period_label(epm_data[:period] || '7_days'), :class => 'daynum')
              tc_options[:heading] << ': '
              tc_options[:heading] << easy_format_hours(epm_data[:hours].to_f)
            end
            tc_options[:heading] << '</span>'
          end
          tc_options
        end

        def get_epm_welcome_toggling_container_options(page_module, _options = {})
          { heading: page_module.module_definition.data_for_language(page_module.settings)['title'] }
        end

        def toggle_open_css_row(uniq_id, user = nil, default = false)
          toggle_button_expanded?(uniq_id, user, default) ? ' open'.html_safe : ''.html_safe
        end

        def toggle_display_style_row(basic_id, entity = nil, user = nil, entity_name = nil, default = false)
          ret = false
          if entity
            if parent = entity.parent
              parent_prefix = basic_id + (entity_name.nil? ? entity.class.name.underscore : entity_name) + '-' + parent.id.to_s
              ret           ||= !toggle_button_expanded?(parent_prefix, user, default)
            end
            if root = entity.root
              root_prefix = basic_id + (entity_name.nil? ? entity.class.name.underscore : entity_name) + '-' + root.id.to_s
              ret         ||= !toggle_button_expanded?(root_prefix, user, default)
            end
          else
            ret ||= !toggle_button_expanded?(basic_id, user, default)
          end

          if ret
            'style="display:none"'.html_safe
          else
            ''.html_safe
          end
        end

        def filter_show_project(f_uniq_id)
          return if f_uniq_id.nil?
          return 'was-hidden'.html_safe if toggle_button_expanded?(f_uniq_id)
        end

        # hide elements for issues and users
        def detect_hide_elements(uniq_id, user = nil, default = true)
          return ''.html_safe if uniq_id.blank?
          return 'style="display:none"'.html_safe if !toggle_button_expanded?(uniq_id, user, default)
        end

        # return options for date and datetime select in easy_query
        def options_for_period_select(value, field = nil, options = {})
          no_category = [
              [l(:label_all_time), 'all'],
              [l(:label_is_not_null), 'is_not_null'],
              [l(:label_is_null), 'is_null']
          ]

          past_items = [
              [l(:label_yesterday), 'yesterday'],
              [l(:label_last_week), 'last_week'],
              [l(:label_last_n_weeks, 2), 'last_2_weeks'],
              [l(:label_last_n_days, 7), '7_days'],
              [l(:label_last_month), 'last_month'],
              [l(:label_last_n_days, 30), '30_days'],
              [l(:label_last_n_days, 90), '90_days'],
              [l(:label_last_year), 'last_year'],
              [l(:label_older_than_n_days, 14), 'older_than_14_days'],
              [l(:label_older_than_n_days, 15), 'older_than_15_days'],
              [l(:label_older_than_n_days, 31), 'older_than_31_days']
          ]

          present_items = [
              [l(:label_today), 'today'],
              [l(:label_this_week), 'current_week'],
              [l(:label_this_month), 'current_month'],
              [l(:label_this_year), 'current_year'],
              [l(:label_last_n_days_next_m_days, :last => 30, :next => 90), 'last30_next90']
          ]

          if options[:disabled_values].is_a? Array
            no_category.delete_if { |item| options[:disabled_values].include?(item[1]) }
            past_items.delete_if { |item| options[:disabled_values].include?(item[1]) }
            present_items.delete_if { |item| options[:disabled_values].include?(item[1]) }
          end

          future_items = Array.new
          if field || options[:show_future]
            present_items << [l(:label_to_today), 'to_today'] if field && eqeoc(:to_today, field, options)
            # future stuff
            future_items << [l(:label_tomorrow), 'tomorrow'] if options[:show_future] || eqeoc(:tomorrow, field, options)
            future_items << [l(:label_from_tomorrow), 'from_tomorrow'] if options[:show_future] || eqeoc(:from_tomorrow, field, options)
            future_items << [l(:label_next_week), 'next_week'] if options[:show_future] || eqeoc(:next_week, field, options)
            future_items << [l(:label_next_n_days, :days => 5), 'next_5_days'] if options[:show_future] || eqeoc(:next_5_days, field, options)
            future_items << [l(:label_next_n_days, :days => 7), 'next_7_days'] if options[:show_future] || eqeoc(:next_7_days, field, options)
            future_items << [l(:label_next_n_days, :days => 10), 'next_10_days'] if options[:show_future] || eqeoc(:next_10_days, field, options)
            future_items << [l(:label_next_n_days, :days => 14), 'next_14_days'] if options[:show_future] || eqeoc(:next_14_days, field, options)
            future_items << [l(:label_next_n_days, :days => 15), 'next_15_days'] if options[:show_future] || eqeoc(:next_15_days, field, options)
            future_items << [l(:label_next_month), 'next_month'] if options[:show_future] || eqeoc(:next_month, field, options)
            future_items << [l(:label_next_n_days, :days => 30), 'next_30_days'] if options[:show_future] || eqeoc(:next_30_days, field, options)
            future_items << [l(:label_next_n_days, :days => 90), 'next_90_days'] if options[:show_future] || eqeoc(:next_90_days, field, options)
            future_items << [l(:label_next_year), 'next_year'] if options[:show_future] || eqeoc(:next_year, field, options)
            # extended stuff
            future_items << [l(:label_after_due_date), 'after_due_date'] if eqeoc(:after_due_date, field, options)
          end

          fiscal_items = [
              [l(:label_last_fiscal_year), 'last_fiscal_year'],
              [l(:label_this_fiscal_year), 'current_fiscal_year'],
              [l(:label_next_fiscal_year), 'next_fiscal_year'],
              [l(:label_last_fiscal_quarter), 'last_fiscal_quarter'],
              [l(:label_this_fiscal_quarter), 'current_fiscal_quarter'],
              [l(:label_next_fiscal_quarter), 'next_fiscal_quarter']
          ]

          custom_items = [
              [l(:label_in_less_than), 'in_less_than_n_days', { 'data-description' => l(:label_in_less_than_description) }],
              [l(:label_in_more_than), 'in_more_than_n_days', { 'data-description' => l(:label_in_more_than_description) }],
              [l(:label_in_next_days), 'in_next_n_days', { 'data-description' => l(:label_in_next_days_description) }],
              [l(:label_in), 'in_n_days', { 'data-description' => l(:label_in_description) }],

              [l(:label_less_than_ago), 'less_than_ago_n_days', { 'data-description' => l(:label_less_than_ago_description) }],
              [l(:label_more_than_ago), 'more_than_ago_n_days', { 'data-description' => l(:label_more_than_ago_description) }],
              [l(:label_in_past_days), 'in_past_n_days', { 'data-description' => l(:label_in_past_days_description) }],
              [l(:label_ago), 'ago_n_days', { 'data-description' => l(:label_ago_description) }],
              [l(:label_last_n_days_next_m_days, :last => 'X', :next => 'Y'), 'from_m_to_n_days', { 'data-description' => l(:label_last_n_days_next_m_days_description) }]
          ] unless options[:hide_custom]

          call_hook(:application_helper_options_for_period_select_bottom, { :past_items => past_items, :present_items => present_items, :future_items => future_items, :custom_items => custom_items, :field => field, :options => options })

          r = Array.new
          r << [nil, no_category]
          r << [l(:label_period_past), past_items]
          r << [l(:label_period_present), present_items]
          r << [l(:label_period_future), future_items] if future_items.any?
          r << [l(:label_period_fiscal), fiscal_items]
          r << [l(:label_period_custom), custom_items] if custom_items

          if options[:additional_items].is_a?(Array)
            r << options[:additional_items]
          end

          if options[:no_html]
            r
          else
            grouped_options_for_select(r, value)
          end
        end

        def render_with_fallback(*attrs)
          raise 'Missing an options argument' unless attrs.last.is_a?(Hash)
          options = attrs.last
          raise 'Missing an fallback prefixes' unless options[:prefixes]
          partial  = options[:partial] || attrs.first
          prefixes = options.delete(:prefixes)

          if prefixes.is_a?(ActiveRecord::Base)
            klass    = prefixes.class
            prefixes = []
            while true
              prefixes << klass.name.underscore.pluralize
              break if klass == klass.base_class
              klass = klass.superclass
            end
          end

          prefixes.each do |prefix|
            if lookup_context.template_exists?(partial, prefix, true)
              partial.prepend("#{prefix}/")
              return render(*attrs)
            end
          end
          partial.prepend("#{prefixes.last}/")
          render(*attrs)
        end

        def easy_page_context
          if is_a?(ApplicationController)
            @__easy_page_ctx
          else
            controller.easy_page_context
          end
        end

        def prepare_easy_page_for_render(tab = nil)
          tab ||= easy_page_context[:page_params][:current_tab]
          if (tabs = easy_page_context[:page_params][:tabs]) && tabs.count > 1 && tab
            html_title(tab.name)
          end

          has_any_module = easy_page_context[:page_modules].inject(false) { |sum, obj| sum || !obj[1].blank? }

          easy_page_context[:page_modules].keys.each_with_index do |zone_name, idx|

            content_for(('easy_page_zone_' + zone_name.underscore).to_sym) do
              s                                             = ''
              current_module_floating, last_module_floating = false, false

              if has_any_module
                easy_page_context[:page_modules][zone_name].each do |page_module|
                  if page_module.module_definition.module_allowed?
                    current_module_floating = page_module.floating?

                    if !current_module_floating && last_module_floating
                      s << '<div class="clear"></div>'
                    end

                    s << render(:partial => "easy_page_layout/page_module_#{easy_page_context[:page_params][:edit] ? 'edit' : 'show'}_container", :locals => { :page_params => easy_page_context[:page_params], :page_module => page_module })

                    last_module_floating = current_module_floating
                  end
                end
              elsif idx == 0 && !easy_page_context[:page_params][:edit]
                s << render(:partial => 'easy_page_modules/empty_zone', :locals => {})
              end

              if s.present? || easy_page_context[:page_params][:edit]
                render(partial: 'easy_page_layout/empty_zone_content', locals: {
                    page_params: easy_page_context[:page_params],
                    zone_name:   zone_name,
                    zone_idx:    idx,
                    content:     s.html_safe,
                    tab_pos:     (tab && tab.position) || 1
                })
              end
            end
          end
        end

        def render_easy_page_editable_tabs
          return unless easy_page_context
          tabs = easy_page_context[:page_params][:tabs]

          if tabs
            current_tab = easy_page_context[:page_params][:current_tab]
            render(:partial => 'common/easy_page_editable_tabs', :locals => { :tabs => tabs, :editable => easy_page_context[:page_params][:edit], :selected_tab => (current_tab && current_tab.position) }) if tabs.size > 0
          end
        end

        def link_to_easy_demo_user(demo_user, options = {})
          link_to_user demo_user, options
        end

        def link_to_entity(entity, options = {}, html_options = {})
          return '' if entity.nil?

          options[:html] ||= {}
          options[:html].merge!(html_options || {})

          case entity.class.name
          when 'Attachment'
            link_to_attachment(entity, options)
          when 'Document'
            link_to_document(entity, options)
          when 'Issue'
            link_to_issue(entity, options)
          when 'Journal'
            link_to_journal(entity, options)
          when 'Project'
            link_to_project(entity, options, html_options)
          when 'User', 'AnonymousUser'
            link_to_user(entity, options)
          when 'News'
            link_to_news(entity, options)
          else
            m = "link_to_#{entity.class.name.underscore}".to_sym
            if respond_to?(m)
              send(m, entity, options)
            else
              link_to(entity, entity, options[:html])
            end
          end
        end

        def edit_entity_path(entity, options = {})
          case entity.class.name
          when 'Issue'
            edit_issue_path(entity, options)
          end
        end

        def webdav_attachment_path(attachment, options = {})
          %{#{webdav_path}/attachment/#{attachment.id}#{File.extname(attachment.filename)}}
        end

        def webdav_attachment_url(attachment, options = {})
          url = +''
          url << url_options[:protocol]
          # url << 'dav://'
          url << url_options[:host]
          url << ":#{url_options[:port]}" if url_options[:port].present?
          url << webdav_attachment_path(attachment, options)
          url
        end

        def link_to_journal(journal, options = {})
          options[:anchor] ||= "journal-#{journal.id}-notes"
          link_to_entity(journal.journalized, options)
        end

        def link_to_document(document, options = {})
          link_to(document.title, url_to_document(document))
        end

        def link_to_easy_issue_timer(issue_timer, options = {})
          "#{content_tag(:span, render_user_attribute(issue_timer.user, link_to_user(issue_timer.user), options))}: #{issue_timer.issue}".html_safe
        end

        def link_to_news(news, options = {})
          link_to(news.title, url_to_news(news))
        end

        def link_to_time_entry(time_entry, options = {})
          link_to("#{format_date(time_entry.spent_on)} - #{time_entry.project}: #{l(:label_f_hour_plural, value: time_entry.hours)}", url_to_time_entry(time_entry))
        end

        def link_to_easy_entity_action(easy_entity_action, options = {})
          link_to(easy_entity_action.name, url_to_easy_entity_action(easy_entity_action))
        end

        def link_to_easy_page(easy_page, options = {})
          if easy_page.is_user_defined?
            link_to(easy_page.identifier, custom_easy_page_url(:identifier => easy_page.identifier))
          end
        end

        def link_to_easy_query_snapshot_data(easy_query_snapshot_data, options = {})
          link_to easy_query_snapshot_data.date, easy_query_snapshot_data.easy_query_snapshot.create_easy_query.queried_class
        end

        # Generates a link to an attachment with a thumbnail.
        # See link_to_attachment
        def link_to_attachment_with_thumbnail(attachment, options = {})
          link_to_attachment(attachment, options).sub(/>.*</, ">#{attachment.image? ? thumbnail_tag(attachment) : 'Show'}<")
        end

        def render_menu_more(menu = nil, entity = nil, options = {}, &block)
          if block.nil?
            links = []
            menu_items_for(menu, entity) do |node|
              links << render_menu_node(node, entity)
            end

            html_links = links.join("\n")
          else
            html_links = with_output_buffer(&block)
          end

          # backward compatible
          if options[:hook] && options[:hook][:name]
            html_links += call_hook(options[:hook][:name], options[:hook][:options])
          end

          return ''.html_safe if html_links.blank?
          return content_tag(:div, :class => "menu-more-container #{options.delete(:menu_more_container_class)}") do
            s = ''
            s << content_tag(:a, options[:label] || l(:label_menu_more), :onclick => "EASY.utils.toggleDiv('menu-more-#{options[:menu_id] || menu.object_id.to_s}'); #{options.delete(:menu_expander_after_function_js)};$(this).toggleClass('icon-remove icon-add')", :class => "menu-expander #{options.delete(:menu_expander_class)}")
            s << content_tag(:div, content_tag('ul', html_links.html_safe), :id => "menu-more-#{options[:menu_id] || menu.object_id.to_s}", :class => "menu-more collapsed #{options.delete(:menu_more_class)}", :style => 'display:none')
            s.html_safe
          end
        end

        def project_heading(project, sub_item_text)
          #          if project
          #            "#{project.name} - #{sub_item_text}"
          #          else
          return "#{sub_item_text}".html_safe
          #          end
        end

        def render_project_heading(project, sub_item_text = nil)
          if sub_item_text.nil?
            item          = Redmine::MenuManager.items(:project_menu).detect { |i| i.name == current_menu_item }
            sub_item_text = item.caption if item
          end
          ctx_view_projects_show_project_heading = { :additional_heading => '', :project => project, :contextual_heading => '' }
          Redmine::Hook.call_hook(:view_projects_show_project_heading, ctx_view_projects_show_project_heading)
          additional_heading = content_tag(:div, ctx_view_projects_show_project_heading[:additional_heading].html_safe, :class => 'additional-heading') if ctx_view_projects_show_project_heading[:additional_heading].to_s.size > 0
          contextual_heading = content_tag(:div, ctx_view_projects_show_project_heading[:contextual_heading].html_safe, :class => 'contextual') if !ctx_view_projects_show_project_heading[:contextual_heading].blank?
          ((contextual_heading || '') + content_tag('h2', project_heading(project, sub_item_text.to_s) + additional_heading.to_s)).html_safe
        end

        def project_header_breadcrump(entity, options = {})
          project    = entity.project if entity.respond_to?(:project)
          project    ||= @project
          breadcrump = Array.new
          breadcrump << link_to(l(:label_templates_plural), templates_path) if project.easy_is_easy_template
          favorite_projects = User.current.favorite_projects.where(:id => project.self_and_ancestors.reorder(nil)).pluck(:id)
          if User.current.allowed_to?(:view_project, project)
            project.self_and_ancestors.preload(:enabled_modules).each do |p|
              project_name = h(p.name)
              project_name << " <span class=\"menu-project-template\">#{l(:label_menu_project_template)}</span>".html_safe if p.easy_is_easy_template?
              project_name << " <span class=\"menu-project-template\">#{l(:field_is_planned)}</span>".html_safe if p.is_planned
              if project.id == p.id
                current_project = content_tag(:span, link_to(project_name, url_to_project(p, :jump => current_menu_item), { :class => 'self' }))
                if favorite_projects.include?(project.id)
                  fav_css = 'icon-fav favorited'
                  title   = l(:label_unfavorite)
                else
                  fav_css = 'icon-fav-off'
                  title   = l(:label_favorite)
                end
                current_project << link_to('', favorite_project_path(p), :method => :post, :remote => true, :class => "icon #{fav_css}", :id => "favorite_project_#{p.id}", :title => title)
                breadcrump << current_project
              else
                breadcrump << link_to_if(p.visible?, project_name, url_to_project(p, :jump => current_menu_item), { :class => 'ancestor' })
              end
            end
          end

          entity_format = options[:link_tail] ? link_to_entity(entity, options) : h(entity.to_s)
          breadcrump << truncate_html(entity_format, 60) if entity && !entity.new_record?

          return breadcrump.join('<span class="separator"> &#187; </span>').html_safe
        end

        def url_to_entity(entity, options = {})
          if entity.is_a?(SimpleDelegator)
            entity = entity.__getobj__
          end

          m = "url_to_#{entity.class.name.demodulize.underscore}".to_sym
          if respond_to?(m)
            send(m, entity, options)
          else
            nil
          end
        end

        def url_standard_options(options = {})
          { :format => options[:format], :anchor => options[:anchor], :only_path => options[:only_path].nil? ? true : options[:only_path] }
        end

        def url_to_attachment(attachment, options = {})
          options[:action] ||= options.delete(:download) ? 'download' : 'show'
          base_url         = { :controller => 'attachments', :action => options[:action], :id => attachment }
          if attachment.is_a?(::AttachmentVersion)
            attributes = { :version => true, :t => attachment.updated_at.to_i }
          else
            attributes = { :filename => attachment.filename, :t => attachment.created_on.to_i }
          end
          { **base_url, **options, **url_standard_options(options), **attributes }
        end

        def url_to_document(document, options = {})
          document_url(document, options.merge(url_standard_options(options)))
        end

        def url_to_version(version, options = {})
          version_url(version, options.merge(url_standard_options(options)))
        end

        def url_to_news(news, options = {})
          news_url(news, options.merge(url_standard_options(options)))
        end

        def url_to_time_entry(time_entry, options = {})
          edit_easy_time_entry_path(time_entry, options)
        end

        def url_to_easy_entity_action(easy_entity_action, options = {})
          easy_entity_action_url(easy_entity_action, options.merge(url_standard_options(options)))
        end

        def url_to_easy_entity_activity(easy_entity_action, options = {})
          easy_entity_activity_url(easy_entity_action, options.merge(url_standard_options(options)))
        end

        def url_to_issue(issue, options = {})
          options[:lock_version] = issue.lock_version if options[:format].to_s == 'json'
          issue_url(issue, options.merge(url_standard_options(options)))
        end

        def url_to_journal(journal, options = {})
          issue_url(journal.issue, :anchor => "journal-#{journal.id}-notes", :only_path => (options[:only_path].nil? ? true : options[:only_path]), :format => options[:format])
        end

        def url_to_project(project, options = {})
          project_url(project, options.merge(url_standard_options(options)))
        end

        def url_to_user(user, options = {})
          profile_user_url(user, options.merge(url_standard_options(options)))
        end

        def url_to_wiki_page(wiki_page, options = {})
          wiki_page_path(wiki_page, url_standard_options(options))
        end

        # Return *true* if item can be added to select
        def eqeoc(key, field, options)
          options ||= {}
          return false if options[:field_disabled_options] && [options[:field_disabled_options][field]].flatten.include?(key)
          return (options[:extended_options] && options[:extended_options].include?(key)) ||
              ((options[:option_limit] && options[:option_limit][key] && options[:option_limit][key].include?(field)))
        end

        def get_scoped_options_for_select(named_scope, selected = nil, name_method = nil, id_method = nil)
          name_method ||= 'to_s'.to_sym
          id_method   ||= 'id'.to_sym

          named_scope_array = named_scope.collect do |entry|
            if name_method.is_a?(Symbol)
              name = entry.send(name_method).to_s
            elsif name_method.is_a?(Proc)
              name = name_method.call(entry).to_s
            end

            if id_method.is_a?(Symbol)
              id = entry.send(id_method).to_s
            elsif id_method.is_a?(Proc)
              id = id_method.call(entry).to_s
            end

            [name, id]
          end
          options_for_select(named_scope_array, selected)
        end

        def scoped_easy_select_tag(name, named_scope, selected_value = nil, load_data_url = nil, options = {})
          raise "scoped_easy_select_tag -> named_scope has to be ActiveRecord::Relation! (instead of #{named_scope.class.name})" unless named_scope.is_a?(ActiveRecord::Relation)

          if options.delete(:force_autocomplete)
            values = nil
          elsif options.delete(:force_select)
            values = get_scoped_options_for_select(named_scope, (selected_value && selected_value[:id]), options.delete(:name), options.delete(:id))
          else
            named_scope_count = named_scope.count
            values            = named_scope_count > EasySetting.value('easy_select_limit').to_i ? nil : get_scoped_options_for_select(named_scope, (selected_value && selected_value[:id]), options.delete(:name), options.delete(:id))
          end

          easy_select_tag(name, selected_value || { :name => '', :id => '' }, values, load_data_url, options)
        end

        def easy_select_tag(name, selected_value, values = nil, load_data_url = nil, options = {})
          options[:onchange] ||= 'null'
          display_no_data    = !options.delete(:no_label_no_data)

          if values.nil?
            easy_autocomplete_tag(name, selected_value, load_data_url, options)
          elsif values.empty?
            if display_no_data
              "<em>#{l(:label_no_data)}</em>".html_safe
            end
          else
            values.insert(0, options_for_select([['', '']])) if options[:include_blank]
            select_tag(name, values, { :onchange => options[:onchange] }.merge(options[:html_options] || {}))
          end
        end

        def easy_autocomplete_tag(name, selected_value, source, options = {})
          root_element                        = options[:root_element].blank? ? 'null' : "'#{options[:root_element]}'"
          options[:html_options]              ||= {}
          options[:easy_autocomplete_options] ||= {}
          id                                  = options[:html_options].delete(:id) || name
          ac                                  = text_field_tag(nil, selected_value[:name], options[:html_options].merge({ :id => id + '_autocomplete' }))
          ac << hidden_field_tag(name, selected_value[:id], :id => id)
          if source.is_a?(Array)
            source = source.to_json
          else
            source = "'#{source}'"
          end
          function = (
            "easyAutocomplete('#{id}', " \
                             "#{source}, " \
                             "function(event, ui) {#{options[:onchange]}}, " \
                                                  "#{root_element}, " \
                                                  "#{options[:easy_autocomplete_options].to_json.tr('"', "'")})"
          )

          data_attr_name = options.dig(:easy_autocomplete_options, :widget).to_s == 'catcomplete' ? 'easy-catcomplete' : 'ui-autocomplete'
          function << ".data('#{data_attr_name}')._renderItem = #{options[:render_item]};" if options[:render_item]

          function             = function.strip
          wrapper_class        = ' easy-autocomplete-tag'
          wrapper_html_options = options[:wrapper_html_options] || {}
          if wrapper_html_options[:class].present?
            wrapper_html_options[:class] += wrapper_class
          else
            wrapper_html_options[:class] = wrapper_class
          end
          wrapper_html_options[:data] = { :easy_autocomplete => Base64.strict_encode64(function.to_s).strip.html_safe }
          return content_tag(:span, ac.html_safe, wrapper_html_options)
        end

        def easy_tag_list_autocomplete_field_tag(taggable_entity, field_name, field_options = {})
          field_options.merge!({ load_immediately: true })
          autocomplete_field_tag(field_name.to_s + '[tag_list][]',
                                 autocomplete_easy_taggables_path(format: :json, suggestions: taggable_entity.tag_list),
                                 taggable_entity.tag_list,
                                 field_options)
        end

        def easy_multiselect_tag(name, possible_values, selected_values, options = {})
          options.reverse_merge!({ select_first_value: true, load_immediately: false })

          options[:id] ||= sanitize_to_id(name)

          content_tag(:span, :class => 'easy-multiselect-tag-container') do
            text_field_tag('', '', (options[:html_options] || {}).merge(id: options[:id])) +
                late_javascript_tag("$('##{options[:id]}').easymultiselect({multiple: true, inputName: '#{name}', preload: true, source: #{possible_values.to_json}, selected: #{selected_values.to_json}, select_first_value: #{options[:select_first_value]}, load_immediately: #{options[:load_immediately]}, autocomplete_options: #{(options[:jquery_auto_complete_options] || {}).to_json} });")
          end
        end

        def easy_combobox_tag(name, possible_values, default_value, options = {})
          options.reverse_merge!({ :select_first_value => true })

          options[:id] ||= sanitize_to_id(name)

          possible_values = possible_values.map { |v| v = v.to_a; { :value => v[0], :id => v[1] || v[0] } }

          html = ""
          html << content_tag(:span, text_field_tag('', '', :id => "#{options[:id]}_autocomplete"), :class => 'easy-autocomplete-tag')
          html << content_tag(:span, '', :id => "#{options[:id]}_entity_array")
          html << late_javascript_tag("easyComboboxTag(#{options[:id].to_json}, #{name.to_json}, #{possible_values.to_json}, [], '#{default_value}');")

          content_tag(:span, html.html_safe, :class => 'easy-multiselect-tag-container')
        end

        def top_menu_items_for_mobile
          links = []
          menu_items_for(:easy_quick_top_menu) do |node|
            next if node.name == :my_page
            links << render_menu_node(node)
          end
          menu_items_for(:top_menu) do |node|
            links << render_menu_node(node)
          end

          return links.join("\n").html_safe
        end

        def easy_color_scheme_select_tag(name, options = {})
          options[:include_blank] = true if options[:include_blank].nil?
          selected                = options.delete(:selected)

          l = Array.new
          l << label_tag("#{name}_", radio_button_tag(name, '', selected.nil?) + l(:label_none), :class => 'colorscheme-item') if options.delete(:include_blank)
          0.upto(EasyExtensions::EasyProjectSettings.easy_color_schemes_count) do |i|
            l << label_tag("#{name}_scheme-#{i}", radio_button_tag(name, "scheme-#{i}", "scheme-#{i}" == selected) + content_tag(:span, l(:sample_text), :class => "scheme-#{i}"), :class => "color-scheme-item" + ("scheme-#{i}" == selected ? ' selected' : ''))
          end

          return content_tag(:span, l.join("\n").html_safe, :class => 'easy-color-scheme-container')
        end

        def options_for_easy_color_scheme(options = {})
          selected       = options.delete(:selected)
          hidden_schemes = options.delete(:hidden_schemes) || []
          options_for_select(
              0.upto(EasyExtensions::EasyProjectSettings.easy_color_schemes_count).collect do |i|
                scheme = "scheme-#{i}"
                [l(:sample_text), scheme, { :class => scheme, :selected => (scheme == selected ? ' selected' : ''), :style => hidden_schemes.include?(scheme) ? 'display:none;' : '' }]
              end, :disabled => options[:disabled]
          )
        end

        def attachment_include_tags
          [javascript_include_tag('redmine_attachments')]
        end

        def include_attachment_tags
          unless @attachment_tags_included
            @attachment_tags_included = true
            content_for :body_bottom do
              attachment_include_tags.join.html_safe
            end
          end
        end

        def galereya_include_tags
          tags = Array.new
          tags << javascript_include_tag('galereya/jquery.galereya.js', defer: true)
          tags << javascript_tag(%{
            EASY.schedule.main(function () {
              EASY.utils.initGalereya = function(elems) {
                var size = #{Setting.thumbnails_size || 100 };
                elems.each(function () {
                  $(this).galereya({size: size});
                });
              };
            });
          })
          tags
        end

        def include_galereya_tags
          unless @galereya_tags_included
            @galereya_tags_included = true
            content_for :body_bottom do
              galereya_include_tags.join.html_safe
            end
          end
        end

        def include_filters_bottom_tags
          unless @filters_bottom_tags_included
            @filters_bottom_tags_included = true

            content_for :body_bottom do
              javascript_tag do
                i18n = {
                    yes:                            l(:general_text_Yes),
                    no:                             l(:general_text_No),
                    label_day_plural:               l(:label_day_plural),
                    label_date_from:                l(:label_date_from),
                    label_date_to:                  l(:label_date_to),
                    text_date_period_is_shifted_by: l(:text_date_period_is_shifted_by),
                    operators:                      EasyQuery.operators.transform_values { |v| l(v) }
                }

                %{
                  EASY.schedule.main(function(){
                    $.easyquery.filters.prototype.options.i18n = #{i18n.to_json}
                  })
                }.html_safe
              end
            end
          end
        end

        def favorited_by_entries(entity, options = {})
          f = entity.favorited_by.includes(:easy_favorites).references(:easy_favorites).where(EasyFavorite.arel_table[:user_id].not_eq(User.current.id))
          f.limit(options[:limit].to_i) if options[:limit].present?
          f
        end

        def authoring_with_datetime(created, author, options = {})
          l(options[:label] || :label_added_datetime_by, :author => link_to_user(author), :datetime => format_time(created)).html_safe
        end

        def render_easy_sliding_panel(name, options = {}, &block)

          yield panel = EasyExtensions::EasySlidingPanel.new(name, self, options)

          render(:partial => 'common/easy_sliding_panel', :locals => { :panel => panel })
        end

        def render_rsb_to_json(**render_options)
          JSON.parse(capture { render(render_options).html_safe })
        end

        def momentjs_date_format
          case (Setting.date_format.presence || I18n.t('date.formats.default'))
          when '%Y-%m-%d'
            'YYYY-MM-DD'
          when '%Y/%m/%d'
            'YYYY/MM/DD'
          when '%d/%m/%Y'
            'DD/MM/YYYY'
          when '%d.%m.%Y'
            'DD.MM.YYYY'
          when '%d-%m-%Y'
            'DD-MM-YYYY'
          when '%m/%d/%Y'
            'MM/DD/YYYY'
          when '%d %b %Y'
            'DD MMM YYYY'
          when '%d %B %Y'
            'DD MMMM YYYY'
          when '%b %d, %Y'
            'MMM DD, YYYY'
          when '%B %d, %Y'
            'MMMM DD, YYYY'
          else
            'D. M. YYYY'
          end
        end

        def momentjs_locale
          case I18n.locale
          when :'pt-BR'
            'pt-br'
          when :zh
            'zh-cn'
          when :'zh-TW'
            'zh-tw'
          when :'sr'
            'sr-cyrl'
          when :'sr-YU'
            'sr'
          when :'no'
            'nb'
          else
            I18n.locale.to_s
          end
        end

        def quarter_name(quarter_idx)
          l('date.quarter_names')[quarter_idx.to_i]
        end

        def convert_form_name_to_id(name)
          name.tr('[', '_').delete(']')
        end

        def render_reorder_handle(obj_or_url, name, options = {})
          url_options = options.delete(:url_options) || {}
          url         = obj_or_url.is_a?(String) ? obj_or_url : polymorphic_path(obj_or_url, url_options)

          content_tag(:span, '&nbsp;'.html_safe, { :data => { :url => url, :name => name }, :class => 'icon-reorder easy-sortable-list-handle', :title => l(:title_reorder_button) }.reverse_merge(options))
        end

        def include_jqplot_scripts
          unless @include_jqplot_scripts_added
            content_for :body_bottom do
              # stylesheet_link_tag('easy_chart/c3.css') +
              javascript_include_tag('easy_chart/easy_chart.js', defer: true) +
                  javascript_tag("EASY.schedule.require(function(){
                  $.extend( $.easy.easy_chart.prototype.i18n, { noData: '#{j l(:label_no_data)}', createBaseline: '#{j l(:label_create_chart_baseline)}',
                  destroyBaseline: '#{j l(:label_delete_chart_baseline)}' } );
                }, function() { return $.easy && $.easy.easy_chart })")
            end
            @include_jqplot_scripts_added = true
          end
        end

        def include_map_scripts
          unless @map_scripts_included
            content_for :header_tags do
              stylesheet_link_tag('//cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/leaflet.css',
                                  '//cdnjs.cloudflare.com/ajax/libs/leaflet.markercluster/0.5.0/MarkerCluster.css',
                                  '//cdnjs.cloudflare.com/ajax/libs/leaflet.markercluster/0.5.0/MarkerCluster.Default.css') +
                  javascript_include_tag('//cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/leaflet.js',
                                         '//cdnjs.cloudflare.com/ajax/libs/leaflet.markercluster/0.5.0/leaflet.markercluster.js')

              # stylesheet_link_tag('https://api.mapbox.com/mapbox.js/v2.4.0/mapbox.css',
              #   'https://api.mapbox.com/mapbox.js/plugins/leaflet-markercluster/v0.4.0/MarkerCluster.css',
              #   'https://api.mapbox.com/mapbox.js/plugins/leaflet-markercluster/v0.4.0/MarkerCluster.Default.css') +
              # javascript_include_tag('https://api.mapbox.com/mapbox.js/v2.4.0/mapbox.js',
              #   'https://api.mapbox.com/mapbox.js/plugins/leaflet-markercluster/v0.4.0/leaflet.markercluster.js')
            end
          end
        end

        def include_google_maps_scripts(options = {})
          unless @include_google_maps_scripts_added
            if options[:callback]
              callback_params = "&callback=#{options[:callback]}"
            else
              callback_params = ''
            end
            if options[:key]
              key_params = "&key=#{options[:key]}"
            else
              key_params = ''
            end

            content_for :header_tags do
              "<script type=\"text/javascript\" src=\"#{Setting.protocol}://maps.googleapis.com/maps/api/js?v=3&sensor=false#{callback_params}#{key_params}\"></script>\n".html_safe +
                  "<script type=\"text/javascript\" src=\"#{Setting.protocol}://google-maps-utility-library-v3.googlecode.com/svn/trunk/markerclusterer/src/markerclusterer_compiled.js\"></script>\n".html_safe
            end
            @include_google_maps_scripts_added = true
          end
        end

        def easy_edit_issue_path(*args)
          options = args.extract_options!
          issue_path(args, options.merge({ edit: true }))
        end

        def easy_edit_issue_url(*args)
          options = args.extract_options!
          issue_url(args, options.merge({ edit: true }))
        end

        # generates an encoding select tag, if given selector_id of containing tag, it selects probably encoding depending on platform
        def easy_encoding_select_tag(selector_id = nil, html_options = {})
          tag = label_tag(:encoding) + select_tag(:encoding, options_for_select(%w(UTF-8 windows-1250 ISO-8859-2)), html_options)
          js  = ''
          if selector_id
            js << '<script type="text/javascript"> '
            js << 'EASY.schedule.late(function(){'
            js << 'var check_widle = /.?(win).?/i; '
            js << 'if (check_widle.test(navigator.platform)) { '
            js << "  $(\"##{selector_id} select\").val(\"windows-1250\"); "
            js << '};'
            js << '})'
            js << '</script>'
          end
          tag.html_safe + js.html_safe
        end

        def rating_stars(value, star_no = 5, options = {})
          if options[:no_html]
            (1 + ((star_no - 1) * (value || 0) / 100)).round.to_s
          else
            s = ::ActiveSupport::SafeBuffer.new
            star_no.times do |i|
              s << content_tag(:span, '<a>&nbsp;</a>'.html_safe, :class => "star-rating rater-1 star star-rating-applied star-rating-readonly#{(value / (100.0 / (star_no - 1))).round >= i ? ' star-rating-on' : ''}")
            end
            content_tag(:span, s, :class => 'star-rating-control')
          end
        end

        def easy_entity_replace_tokens(entity, text)
          return nil if entity.nil? || text.nil?

          text = text.dup
          entity.easy_entity_replacable_tokens.each do |token, column|
            text.gsub!(Regexp.new("%\s?#{token}\s?%")) do
              format_entity_attribute(entity.class, column, column.value(entity), { :entity => entity, :inline_editable => false }).to_s
            end
          end

          text
        end

        def easy_entity_replace_token_link(token, column, text_area_id, options = {})
          js = ''
          if Setting.text_formatting == 'HTML'
            js = "CKEDITOR.instances['#{text_area_id}'].insertText('%#{token}%');"
          else
            js = "$('##{text_area_id}').val($('##{text_area_id}').val() + '%#{token}%');"
          end

          if options[:close_modal]
            js << 'hideModal();'
          end

          link_to_function(column.caption, js, :title => column.caption)
        end

        def render_mail_template_dynamic_tokens(entity_klass, text_area_id)
          return '' if !entity_klass.respond_to?(:easy_mail_template_tokens)
          html = Setting.text_formatting == 'HTML'
          entity_klass.easy_mail_template_tokens.collect do |token_or_tokens, replacable_method|
            js = ''
            if html
              js = "CKEDITOR.instances['#{text_area_id}'].insertText('%#{token_or_tokens.first}%');"
            else
              js = "$('##{text_area_id}').val($('##{text_area_id}').val() + '%#{token_or_tokens.first}%')"
            end

            link_to_function(l(token_or_tokens.first, :scope => [:easy_mail_template_token, :caption]), js, :title => l(token_or_tokens.first, :scope => [:easy_mail_template_token, :title]))
          end.join(html ? '<br />' : "\n").html_safe
        end

        def conditional_content_tag(condition, tag_name, options_for_tag = nil, &block)
          if condition
            content_tag(tag_name, options_for_tag, &block)
          else
            capture(&block)
          end
        end

        def entity_assigned_to_collection_for_select_options(entity, project = nil, options = {})
          project ||= entity.project
          m       = "#{entity.class.name.underscore}_assigned_to_collection_for_select_options".to_sym
          if respond_to?(m)
            send(m, entity, project, options)
          elsif entity.respond_to?(:assignable_users)
            if options[:external]
              assignables = entity.external_assignable_users
            else
              assignables = entity.assignable_users
            end
            assignables = assignables.group_by(&:type)
            assignables['User']  ||= []
            assignables['Group'] ||= []

            assignable_users_for_options  = []
            assignable_groups_for_options = []

            if assignables['User'].include?(User.current)
              assignable_users_for_options << ["<< #{l(:label_me)} >>".html_safe, User.current.id]
            end

            unless entity.new_record?
              if entity.respond_to?(:author_id) && entity.author&.active?
                assignable_users_for_options << [l(:label_author_assigned_to), entity.author_id]
              end
              if entity.respond_to?(:last_user_assigned_to) && entity.respond_to?(:assigned_to_id) &&
                  ((entity.last_user_assigned_to.is_a?(User) && entity.last_user_assigned_to.active?) ||
                      (entity.last_user_assigned_to.is_a?(Group) && Setting.issue_group_assignment?)) &&
                  entity.assigned_to_id != entity.last_user_assigned_to.id
                assignable_users_for_options << [l(:label_last_user_assigned_to), entity.last_user_assigned_to.id]
              end
            end

            assignable_users_for_options.concat(assignables['User'].collect { |m| [m.name, m.id] })
            assignable_groups_for_options.concat(assignables['Group'].collect { |m| [m.name, m.id] })

            assignables_for_options = []
            assignables_for_options << [l(:label_issue_assigned_to_users), assignable_users_for_options] if assignable_users_for_options.any?
            assignables_for_options << [l(:label_issue_assigned_to_groups), assignable_groups_for_options] if assignable_groups_for_options.any?
            assignables_for_options
          else
            []
          end
        end

        def context_menu_with_container(url, container = 'table.list')
          late_javascript_tag("EASY.contextMenu.addContextMenuFor( '#{ url_for(url) }', '#{container}' )") if url
        end

        def easy_query_context_menu(easy_query, modul_uniq_id)
          context_menu_with_container(easy_query.entity_context_menu_path, modul_uniq_id) if easy_query && !easy_query.entity_context_menu_path.blank?
        end

        # source_entity => @easy_contact, @issue
        # referenced_entity_type => Issue, Project, EasyCrmCase
        def render_easy_entity_assignments(source_entity, referenced_entity_type, options = {}, &block)
          options                              ||= {}
          options[:referenced_collection_name] ||= referenced_entity_type.name.pluralize.underscore
          # performance reasons - if there are no referenced entities ( should be quick check )... saves building a query
          return '' if !source_entity.respond_to?(options[:referenced_collection_name]) || source_entity.__send__(options[:referenced_collection_name]).empty?

          project_id       = options[:project].is_a?(Project) ? options[:project].id : options[:project]
          easy_query_class = EasyExtensions::EasyTag::easy_query_class(referenced_entity_type, options)

          return '' if easy_query_class.nil? || !(easy_query_class < EasyQuery)

          query                = easy_query_class.new(:name => 'c_query')
          query.render_context = 'entity_assignments'
          if options[:referenced_collection_name]
            query.set_entity_scope(source_entity.send(options[:referenced_collection_name]).visible)
          end
          query.from_params((options[:query_params] || {}).merge('set_filter' => '1'))
          referenced_entities_count = query.entity_count
          query.output              = query.default_outputs ||
                                      (referenced_entities_count > 3 ? 'list' : 'tiles')
          if query.outputs.include?('list')
            sort_init(query.sort_criteria_init)
            sort_update(query.sortable_columns)
          end
          query.column_names = options[:query_column_names] unless options[:query_column_names].blank?
          query.group_by     = nil

          options[:module_name]    ||= "entity_#{source_entity.class.name.to_id}_#{source_entity.id}_#{options[:referenced_collection_name].to_s}"
          options[:heading_label]  ||= "label_#{referenced_entity_type.name.underscore}_plural"
          options[:heading]        ||= l(options[:heading_label], :default => 'Heading')
          options[:hascontextmenu] ||= true

          if options[:context_menus_path].nil?
            options[:context_menus_path] ||= [
                "context_menu_#{options[:referenced_collection_name]}_path".to_sym,
                "context_menus_#{options[:referenced_collection_name]}_path".to_sym,
                "#{options[:referenced_collection_name]}_context_menu_path".to_sym
            ].detect do |m|
              m if respond_to?(m)
            end
          end

          render(partial: 'easy_queries/easy_entity_assignments_container', locals: {
              source_entity:             source_entity,
              query:                     query, referenced_entity_type: referenced_entity_type,
              referenced_entities_count: referenced_entities_count,
              project:                   project_id, options: options })
        end

        alias_method :render_easy_entity_cards, :render_easy_entity_assignments

        def easy_entity_exports(entity, options = {})
          m = "easy_#{entity.class.name.underscore}_exports".to_sym
          if respond_to?(m)
            send(m, entity, options)
          else
            {}
          end
        end

        def easy_export_name(export_type)
          case export_type
          when :pdf
            'PDF'
          when :ics
            'iCal'
          when :qr
            'QR'
          end
        end

        def easy_issue_exports(issue, options = {})
          {
              pdf: {},
              ics: {},
              qr:  { remote: true }
          }
        end

        def link_to_user_vcard_export(name, path, options = {})
          link_to_entity_mapper(name, path, User, EasyExtensions::Export::EasyVcard, options)
        end

        def easy_user_exports(user, options = {})
          {
              vcf: { link_method: :link_to_user_vcard_export },
              qr:  { remote: true, link_method: :link_to_user_vcard_export }
          }
        end

        def render_easy_entity_card(entity, source_entity, options = {})
          return '' if entity.nil? || source_entity.nil?

          m = "render_easy_entity_card_#{entity.class.name.underscore}".to_sym
          if respond_to?(m)
            send(m, entity, source_entity, options)
          else
            easy_entity_card(entity, source_entity, options) do |eec|
              eec.link_to_entity link_to_entity(entity)
            end
          end
        end

        def easy_entity_card(entity, source_entity, options = {}, &block)
          eec = EasyExtensions::EasyEntityCards::Base.new(entity, source_entity, options)

          yield eec

          render :partial => 'easy_entity_cards/common', :locals => { :easy_entity_card => eec, :options => options.merge({ :easy_entity_card => eec }) }
        end

        def render_easy_entity_card_issue(issue, source_entity, options = {})
          easy_entity_card(issue, source_entity, options) do |eec|
            eec.link_to_entity link_to("#{issue.tracker.name}: #{issue.to_s}", url_to_issue(issue))
            eec.avatar(avatar(issue.assigned_to, :style => :medium, :no_link => true)) if issue.assigned_to
            eec.detail(controller.render_to_string :partial => 'easy_entity_cards/easy_entity_card_issue_detail', :layout => false, :formats => [:html], :locals => { :issue => issue, :options => options })

            eec.footer_left content_tag(:span, issue.tag_list.map { |t| link_to(t, easy_tag_path(t)) }.join(', ').html_safe, :class => 'entity-array') if !issue.tag_list.blank?
            cl = []
            cl << link_to('PDF', url_to_issue(issue, :format => :pdf), :class => 'icon icon-pdf', :title => l(:title_other_formats_links_pdf))
            cl << link_to('iCal', url_to_issue(issue, :format => :ics), :class => 'icon icon-ics', :title => l(:title_other_formats_links_ics))
            cl << link_to('QR', url_to_issue(issue, :format => :qr), :remote => true, :class => 'icon icon-qr', :title => l(:title_other_formats_links_qr))
            eec.footer_right cl.join(' ')
          end
        end

        def render_easy_entity_card_user(user, source_entity, options = {})
          easy_entity_card(user, source_entity, options) do |eec|
            eec.link_to_entity link_to_user(user)
            eec.avatar avatar(user, :style => :medium, :no_link => true)
            eec.detail(controller.render_to_string :partial => 'easy_entity_cards/easy_entity_card_user_detail', :layout => false, :formats => [:html], :locals => { :user => user, :options => options })

            eec.footer_left content_tag(:span, user.tag_list.map { |t| link_to(t, easy_tag_path(t)) }.join(', ').html_safe, :class => 'entity-array') if !user.tag_list.blank?
            cl = []
            cl << link_to_entity_mapper('vCard', user_path(user, :format => 'vcf'), User, EasyExtensions::Export::EasyVcard, :class => 'icon icon-vcard', :title => l(:title_other_formats_links_vcard))
            cl << link_to_entity_mapper('QR', user_path(user, :format => 'qr'), User, EasyExtensions::Export::EasyVcard, :class => 'icon icon-qr', :title => l(:title_other_formats_links_qr), :remote => true)
            eec.footer_right cl.join(' ')
          end
        end

        def render_easy_entity_card_project(project, source_entity, options = {})
          easy_entity_card(project, source_entity, options) do |eec|
            eec.link_to_entity link_to_project(project)
            eec.avatar avatar(project.author, :style => :medium, :no_link => true)
            eec.detail(controller.render_to_string :partial => 'easy_entity_cards/easy_entity_card_project_detail', :layout => false, :formats => [:html], :locals => { :project => project, :options => options })
            eec.footer_left content_tag(:span, project.tag_list.map { |t| link_to(t, easy_tag_path(t)) }.join(', ').html_safe, :class => 'entity-array') if !project.tag_list.blank?
          end
        end

        def render_easy_entity_card_easy_page(easy_page, source_entity, options = {})
          easy_entity_card(easy_page, source_entity, options) do |eec|
            eec.link_to_entity link_to_easy_page(easy_page)
            eec.detail(controller.render_to_string :partial => 'easy_entity_cards/easy_entity_card_easy_page_detail', :layout => false, :formats => [:html], :locals => { :easy_page => easy_page, :options => options })
            eec.footer_left content_tag(:span, easy_page.tag_list.map { |t| link_to(t, easy_tag_path(t)) }.join(', ').html_safe, :class => 'entity-array') if !easy_page.tag_list.blank?
          end
        end

        def render_ul_act_as_tree(entities, options = {}, &block)
          return if entities.blank?

          concat('<ul>'.html_safe)
          entities.each do |entity|
            concat('<li>'.html_safe)

            yield(entity)

            render_ul_act_as_tree(entity.children, options, &block)

            concat('</li>'.html_safe)
          end
          concat('</ul>'.html_safe)
        end

        def easy_other_formats_links(options = {})
          opts = { utm_campaign: 'export_links' }.merge(options)
          if options[:no_container]
            yield EasyExtensions::Export::EasyOtherFormatsBuilder.new(self, opts)
          else
            concat('<div class="other-formats">'.html_safe)
            yield EasyExtensions::Export::EasyOtherFormatsBuilder.new(self, opts)
            concat('</div>'.html_safe)
          end
        end

        # *url* = url for new entity path -> redirect to form for new entity and pre-fill from mapping entity
        # *entity_{from|to}_class* = class name of mapping to mapped entity
        # *html_options* = regular link_to html_options (class, id, data, etc...)
        #   *force_map* = always show mapping table
        def link_to_entity_mapper(name, url, entity_from_class, entity_to_class, html_options = nil, &block)
          html_options ||= {}

          if EasyEntityAttributeMap.where(:entity_from_type => entity_from_class.to_s, :entity_to_type => entity_to_class.to_s).empty? || html_options.delete(:force_map)
            link_to(name, easy_entity_attribute_maps_path(:entity_from => entity_from_class.to_s, :entity_to => entity_to_class.to_s, :url => url, :remote => html_options.delete(:remote), :method => html_options.delete(:method)), html_options.merge({ :remote => true, :method => :get }))
          else
            link_to(name, url, html_options)
          end
        end

        def link_to_google_map(address, options = {})
          return if address.blank?

          google_maps_url = "https://maps.google.com/maps?f=q&q=#{address}&ie=UTF8&om=1"

          css = 'icon icon-globe'
          css << ' button' if options[:show_as_button]

          link_to(google_maps_url, :class => css, :target => '_blank', :title => l(:button_show_on_google_map)) do
            content_tag(:span, options[:name] || l(:button_show_on_google_map), :class => 'tooltip')
          end
        end

        def render_easy_qr(text, options = {})
          render :partial => 'easy_qr/easy_qr', :locals => { :easy_qr => EasyQr.generate_qr(text), :size => options[:size] }
        end

        def render_easy_tel_qr(telephone, options = {})
          render :partial => 'easy_qr/easy_qr', :locals => { :easy_qr => EasyQr.generate_qr("tel:#{telephone}"), :size => options[:size] }
        end

        def render_suggester_jump_box
          easy_autocomplete_tag('search_q',
                                { id: '' },
                                easy_autocomplete_path('visible_search_suggester_entities', jump: current_menu_item),
                                include_blank:             true,
                                root_element:              'suggest_entities',
                                no_label_no_data:          true,
                                force_autocomplete:        true,
                                html_options:              {
                                    type:        'search',
                                    accesskey:   accesskey(:quick_search),
                                    placeholder: l(:label_search),
                                    onfocus:     'EASY.schedule.require('\
                                                    'function() { EASY.search.suggesterFocus() }, '\
                                                    'function() { return (EASY.search && EASY.search.suggesterInitialized) }'\
                                                 ')'
                                },
                                easy_autocomplete_options: {
                                    no_button:  true,
                                    auto_focus: false,
                                    widget:     'suggester',
                                    delay:      1000,
                                }
          )
        end

        def sorted_menu_items_for(menu, project = nil)
          menu_items_for(menu)
        end

        def issue_journal_id_link(journal, entity)
          link_to(issue_path(entity, :anchor => "change-#{journal.id}"), :class => 'journal journal-id', :title => "#{truncate(h(entity.subject), :length => 100)} (#{entity.status})") do
            (content_tag(:i, '', :class => 'icon-link') + content_tag(:span, journal.id.to_s)).html_safe
          end
        end

        def render_more_attributes_button(uniq_id, user_id, collapsed = true)
          tags = ''.html_safe
          tags << content_tag(:a, content_tag(:span, l(:label_more)) + content_tag(:span, l(:label_less)),
                              :href    => 'javascript:void(0);',
                              :onclick => "$(this).toggleClass('icon-add icon-remove open').closest('.easy-entity-details-header-attributes').toggleClass('open');
                                  EASY.utils.updateUserPref('#{uniq_id}', #{user_id}, !$(this).closest('.easy-entity-details-header-attributes').hasClass('open'));",
                              :class   => "more-attributes-toggler#{collapsed ? ' icon-add' : ' icon-remove open'}")

          tags << javascript_tag("EASY.utils.loadDetailAttributes('#{uniq_id}')")
          tags
        end

        def sort_wrapped_principals(wrapped_principals, options = {})
          options[:include_group_members] = true if options[:include_group_members].nil?

          groupped_user_ids = []
          group_principals  = []

          wrapped_principals.each do |group_wrapper|
            next if group_wrapper.principal.nil? || !group_wrapper.principal.is_a?(Group)
            group_principals << group_wrapper

            if options[:include_group_members]
              groupped_before_this_group_ids = groupped_user_ids.dup
            end

            group_user_ids = group_wrapper.principal.user_ids
            groupped_user_ids << group_wrapper.user_id
            groupped_user_ids.concat group_user_ids

            if options[:include_group_members]
              group_principals.concat wrapped_principals.select { |principal| principal.user_id.in?(group_user_ids - groupped_before_this_group_ids) }
            end
          end

          wrapped_principals.reject { |member| groupped_user_ids.include?(member.user_id) } + group_principals
        end

        def entity_fields_rows
          r = IssuesHelper::IssueFieldsRows.new
          yield r
          r.to_html
        end

        def original_url
          url = params[:original_url]
          if url.nil? && request_url = request.original_url
            url = CGI.unescape(request_url.to_s)
          end
          url
        end

        # if formatted, then returns principal options for autocomplete
        # else returns visible principals scope
        def visible_principals_values(formatted: false, filter_statement: nil, options: {})
          options             ||= {}
          internal_non_system = options[:internal_non_system].present?
          include_groups      = options[:include_groups].present?
          project_id          = options[:project_id].presence
          term                = options[:term] || ''
          limit               = EasySetting.value('easy_select_limit').to_i unless options[:no_limit]

          if include_groups
            scope = Principal.active.visible.sorted
          else
            scope = User.active.visible.sorted
            scope = scope.easy_type_internal if internal_non_system
          end

          if /^\d+$/.match?(term)
            scope = scope.where(id: term)
          else
            scope = scope.like(term).limit(limit)
          end

          scope = scope.joins(:members).where("#{Member.table_name}.project_id = ?", project_id.to_i).distinct if project_id
          scope = scope.non_system_flag if internal_non_system
          scope = scope.where(filter_statement) if filter_statement.present?

          scope = scope.where.not(id: GroupBuiltin.ids)
          if formatted
            scope.to_a.map { |principal| [principal.to_s, principal.id.to_s] }
          else
            scope
          end
        end

        def issues_with_children_values(formatted: false, filter_statement: nil, options: {})
          options ||= {}
          term    = options[:term] || ''
          limit   = EasySetting.value('easy_select_limit').to_i unless options[:no_limit]

          if /^\d+$/.match?(term)
            values = Array(Issue.visible.where("#{Issue.table_name}.rgt - #{Issue.table_name}.lft > 1").joins(:project).where(get_project_if_exist).find_by(id: term))
          else
            scope  = Issue.visible.where("#{Issue.table_name}.rgt - #{Issue.table_name}.lft > 1").joins(:project).where(get_project_if_exist).like(term).limit(limit)
            scope  = scope.where(filter_statement) if filter_statement.present?
            values = scope.to_a
          end
          values = values.map { |value| [value.to_s, value.id.to_s] } if formatted

          values
        end

        def get_project_if_exist
          if params[:source_options]&.[](:project_id).present?
            { project_id: params[:source_options][:project_id] }
          else
            { projects: { easy_is_easy_template: false } }
          end
        end

        def add_easy_page_zone_module_data(module_id)
          return unless module_id.present?
          epzm = EasyPageZoneModule.find_by(uuid: module_id)
          return unless epzm

          if epzm.settings.is_a?(Hash)
            settings = epzm.settings
            settings.delete('query_id') if settings['query_type'] == '2'
            params.merge!(settings)
            params[:set_filter] = '1'
          end
          if epzm.easy_pages_id == EasyPage.find_by(page_name: 'project-overview').id && epzm.entity_id
            @project = Project.find_by(id: epzm.entity_id)
          end
        end

        def easy_cocoon_tags
          unless @easy_cocoon_tags_included
            @easy_cocoon_tags_included = true
            javascript_include_tag 'cocoon', defer: true
          end
        end

        def assignables_autocomplete_options_for_edit(assignables)
          autocomplete_items = [{ label: l(:label_nobody), id: 'none' }]
          if assignables.include?(User.current)
            autocomplete_items.concat([{ label: "<< #{l(:label_me)} >>", id: User.current.id }])
          end
          autocomplete_items.concat(assignables.map { |a| { label: a.name, id: a.id } })

          call_hook :application_helper_assignables_autocomplete_options_for_edit_bottom, autocomplete_items: autocomplete_items, assignables: assignables
          autocomplete_items
        end

        def principals_additional_autocomplete_options(assignable_principals, options: {})
          additional_select_options = {}
          if options[:term].present?
            return additional_select_options
          end
          additional_select_options.merge!(User.additional_select_options)
          additional_select_options.merge!(Group.additional_select_options) if options[:include_groups].present?

          # Adding options from params
          #
          # @example
          #   params = {
          #     source_options: {
          #       additional_select_options: "LABEL_1|VALUE_1;LABEL_2|VALUE_2"
          #       select_options_ignored: "VALUE_1;VALUE_2"
          #     }
          #   }
          #
          params_additional_select_options = options[:additional_select_options]
          if params_additional_select_options.is_a?(String)
            extra_options = params_additional_select_options.split(';')

            extra_options.each do |option|
              name, value                     = option.split('|', 2)
              additional_select_options[name] = value
            end
          end

          params_select_options_ignored = options[:select_options_ignored]
          if params_select_options_ignored.is_a?(String)
            extra_options = params_select_options_ignored.split(';')

            extra_options.each do |option|
              additional_select_options.reject! { |name, value| value.to_s === option }
            end
          end
          additional_select_options
        end
      end
    end

    module InstanceMethods

      def calendar_for_with_easy_extensions(field_id)
        include_calendar_headers_tags
        late_javascript_tag("easyDatePicker('##{field_id}', #{!!EasySetting.value(:html5_dates)});")
      end

      def checked_image_with_easy_extensions(checked = true)
        if checked
          return(content_tag(:i, '', :class => 'icon-checked', :title => l(:general_text_Yes)))
        end
      end

      # Renders flash messages
      def render_flash_messages_with_easy_extensions
        s = ''
        flash.each do |k, v|
          s << content_tag(:div, content_tag(:span, v.html_safe) + link_to_function('', "$(this).closest('.flash').fadeOut(500, function(){$(this).remove()})", :class => 'icon-close'), :class => "flash #{k}")
        end
        s.html_safe
      end

      def parse_headings_with_easy_extensions(text, project, obj, attr, only_path, options)
        return if Setting.text_formatting == 'HTML'
        parse_headings_without_easy_extensions(text, project, obj, attr, only_path, options)
      end

      def link_to_project_with_easy_extensions(project, options = {}, html_options = {})
        options[:only_path] = false unless respond_to?(:projects_path)
        project_name        = []
        if n = options.delete(:name_prefix)
          project_name << n unless n.blank?
        end
        if options.delete(:family_name)
          project_name << project.family_name
        else
          project_name << project.name
        end
        if n = options.delete(:name_suffix)
          project_name << n unless n.blank?
        end

        project_name = h(project_name.join(' - '))

        if project.archived?
          project_name
        else
          link_to(project_name, url_to_project(project, options), { :title => project_name }.merge(html_options))
        end
      end

      # Displays a link to user's account page if active
      def link_to_user_with_easy_extensions(user, options = {})
        if user.is_a?(User) && user.visible?
          name = h(user.name(options.delete(:format)))
          if user.active? || (User.current.admin? && user.logged?)
            options[:only_path] = false unless respond_to?(:users_path)
            link                = link_to(name, url_to_user(user, options), :remote => true, :class => user.css_classes, :title => l(:title_user_detail))

            if EasyAttendance.enabled? && options[:only_path].nil? && !User.current.in_mobile_view?
              link << content_tag(:span, '', :data => { id: user.id }, :class => 'attendance-user-status')
            end
          end
        end

        content_tag(:span, link || h(user.to_s), :class => 'add-user-links', :data => { :id => user.is_a?(User) && user.id })
      end

      def link_to_attachment_with_easy_extensions(attachment, options = {})
        text                  = options.delete(:text) || attachment.filename
        html_options          = options.delete(:html_options) || {}
        html_options[:title]  = options.delete(:title) || l(:title_download_attachment)
        html_options[:target] = options.delete(:target) || '_blank'
        html_options[:class]  = options.delete(:class) if options.has_key?(:class)
        options               = options.merge(options.delete(:url)) if options.has_key?(:url)
        link_to(text, url_to_attachment(attachment, options), html_options)
      end

      def format_activity_description_with_easy_extensions(text)
        truncate_html(text.to_s, 120).html_safe
      end

      def project_tree_options_for_select_with_easy_extensions(projects, options = {}, &block)
        s = ''

        ancestors           = Array.new
        ancestor_conditions = projects.collect { |project| "(#{Project.table_name}.lft < #{project.lft} AND #{Project.table_name}.rgt > #{project.rgt})" }
        if ancestor_conditions.any?
          ancestor_conditions = "(#{ancestor_conditions.join(' OR ')}) AND (projects.id NOT IN (#{projects.collect(&:id).join(',')}))"
          ancestors           = Project.where(ancestor_conditions)
        end

        projects = projects.to_a unless projects.is_a?(Array)
        projects << ancestors

        project_tree(projects.flatten.uniq) do |project, level|
          name_prefix    = (level > 0 ? ('&nbsp;' * 2 * level + '&#187; ') : '').html_safe
          selected_value = project

          unless options.empty?
            if (options[:selected].is_a?(Array) && options[:selected].size > 0)
              first_item     = options[:selected].first
              selected_value = (first_item.is_a?(String) ? project.id.to_s : project.id) if first_item.class != project.class
            elsif (!options[:selected].blank? && !options[:selected].is_a?(Array))
              if (options[:selected].is_a?(Project) && options[:selected].id == project.id)
                selected_value = options[:selected]
              elsif (options[:selected].is_a?(String) && options[:selected] == project.id.to_s)
                selected_value = options[:selected]
              end
            end

            tag_options = { :value => project.id, :selected => (option_value_selected?(selected_value, options[:selected]) ? 'selected' : nil) }
          else
            tag_options = { :value => project.id, :selected => nil }
          end

          if ancestors.include?(project)
            tag_options[:style]    = 'font-style:italic'
            tag_options[:disabled] = true
          end
          tag_options.merge!(yield(project)) if block_given?

          s << content_tag('option', (name_prefix + h(project)).html_safe, tag_options)
        end

        unless options.empty?
          if options[:include_blank]
            s = "<option value=\"\">#{options[:include_blank] if options[:include_blank].kind_of?(String)}</option>\n" + s
          end
          if options[:selected].blank? && options[:prompt]
            prompt = options[:prompt].kind_of?(String) ? options[:prompt] : I18n.translate('support.select.prompt', :default => 'Please select')
            s      = "<option value=\"\">#{prompt}</option>\n" + s
          end
        end

        s.html_safe
      end

      def breadcrumb_with_easy_extensions(*args)
        elements = args.flatten
        elements.any? ? content_tag('p', (args.join("<span class=\"separator\"> \xc2\xbb </span>")).html_safe, :class => 'breadcrumb') : nil
      end

      def parse_redmine_links_with_easy_extensions(text, default_project, obj, attr, only_path, options)
        # do not find results with style="color: #xxx"
        text.gsub!(ApplicationHelper::EASY_STYLES_RE) do |m|
          m.tr('#', "\u2236")
        end

        text.gsub!(ApplicationHelper::EASY_LINKS_RE) do |_|
          tag_content        = $~[:tag_content]
          leading            = $~[:leading]
          esc                = $~[:esc]
          project_prefix     = $~[:project_prefix]
          project_identifier = $~[:project_identifier]
          prefix             = $~[:prefix]
          repo_prefix        = $~[:repo_prefix]
          repo_identifier    = $~[:repo_identifier]
          sep                = $~[:sep1] || $~[:sep2] || $~[:sep3] || $~[:sep4]
          identifier         = $~[:identifier1] || $~[:identifier2] || $~[:identifier3]
          comment_suffix     = $~[:comment_suffix]
          comment_id         = $~[:comment_id]

          if tag_content
            $&
          else
            link    = nil
            project = default_project
            if project_identifier
              project = Project.visible.find_by_identifier(project_identifier)
            end
            if esc.nil?
              if prefix.nil? && sep == 'r'
                if project
                  if repo_identifier
                    repository = project.repositories.detect { |repo| repo.identifier == repo_identifier }
                  else
                    repository = project.repository
                  end
                  # project.changesets.visible raises an SQL error because of a double join on repositories
                  if repository
                    @parse_changeset_visible_scope ||= Changeset.visible
                    if (changeset = @parse_changeset_visible_scope.find_by(:repository_id => repository.id, :revision => identifier))
                      link = link_to(h("#{project_prefix}#{repo_prefix}r#{identifier}"),
                                     { :only_path     => only_path, :controller => 'repositories',
                                       :action        => 'revision', :id => project,
                                       :repository_id => repository.identifier_param,
                                       :rev           => changeset.revision },
                                     :class => 'changeset',
                                     :title => truncate_single_line_raw(changeset.comments, 100))
                    end
                  end
                end
              elsif sep == '#' || sep == '##'
                oid = identifier.to_i
                case prefix
                when nil
                  if oid.to_s == identifier
                    @parse_issue_visible_scope ||= Issue.visible
                    if issue = @parse_issue_visible_scope.find_by(:id => oid)
                      anchor = comment_id ? "note-#{comment_id}" : nil
                      url    = issue_url(issue, :only_path => only_path, :anchor => anchor)
                      link   = if sep == '##'
                                 link_to("#{issue.tracker.name} ##{oid}#{comment_suffix}",
                                         url,
                                         :class => issue.css_classes,
                                         :title => "#{issue.tracker.name}: #{issue.subject.truncate(100)} (#{issue.status.name})") + ": #{issue.subject}"
                               else
                                 link_to("##{oid}#{comment_suffix}",
                                         url,
                                         :class => issue.css_classes,
                                         :title => "#{issue.tracker.name}: #{issue.subject.truncate(100)} (#{issue.status.name})")
                               end
                    end
                  end
                when 'document'
                  @parse_document_visible_scope ||= Document.visible
                  if document = @parse_document_visible_scope.find_by(:id => oid)
                    link = link_to(document.title, document_url(document, :only_path => only_path), :class => 'document')
                  end
                when 'version'
                  @parse_version_visible_scope ||= Version.visible
                  if version = @parse_version_visible_scope.find_by(:id => oid)
                    link = link_to(version.name, version_url(version, :only_path => only_path), :class => 'version')
                  end
                when 'message'
                  @parse_message_visible_scope ||= Message.visible
                  if message = @parse_message_visible_scope.find_by(:id => oid)
                    link = link_to_message(message, { :only_path => only_path }, :class => 'message')
                  end
                when 'forum'
                  @parse_forum_visible_scope ||= Board.visible
                  if board = @parse_forum_visible_scope.find_by(:id => oid)
                    link = link_to(board.name, project_board_url(board.project, board, :only_path => only_path), :class => 'board')
                  end
                when 'news'
                  @parse_news_visible_scope ||= News.visible
                  if news = @parse_news_visible_scope.find_by(:id => oid)
                    link = link_to(news.title, news_url(news, :only_path => only_path), :class => 'news')
                  end
                when 'project'
                  @parse_project_visible_scope ||= Project.visible
                  if p = @parse_project_visible_scope.find_by(:id => oid)
                    link = link_to_project(p, { :only_path => only_path }, :class => 'project')
                  end
                when 'user'
                  @parse_users_visible_scope ||= User.visible
                  u                          = @parse_users_visible_scope.find_by(:id => oid, :type => 'User')
                  link                       = link_to_user(u) if u
                else
                  if (klass = prefix.classify.safe_constantize)
                    @parse_polymorphic_visible_scope        ||= {}
                    @parse_polymorphic_visible_scope[klass] ||= klass.respond_to?(:visible) ? klass.visible : klass
                    if entity = @parse_polymorphic_visible_scope[klass].find_by(:id => oid)
                      link = link_to_entity(entity, { :only_path => only_path }, { :class => prefix })
                    end
                  end
                end
              elsif sep == ':'
                # removes the double quotes if any
                name = identifier.gsub(%r{^"(.*)"$}, "\\1")
                name = CGI.unescapeHTML(name)
                case prefix
                when 'document'
                  if project && document = project.documents.visible.find_by_title(name)
                    link = link_to(document.title, document_url(document, :only_path => only_path), :class => 'document')
                  end
                when 'version'
                  if project && version = project.versions.visible.find_by_name(name)
                    link = link_to(version.name, version_url(version, :only_path => only_path), :class => 'version')
                  end
                when 'forum'
                  if project && board = project.boards.visible.find_by_name(name)
                    link = link_to(board.name, project_board_url(board.project, board, :only_path => only_path), :class => 'board')
                  end
                when 'news'
                  if project && news = project.news.visible.find_by_title(name)
                    link = link_to(news.title, news_url(news, :only_path => only_path), :class => 'news')
                  end
                when 'commit', 'source', 'export'
                  if project
                    repository = nil
                    if name =~ %r{^(([a-z0-9\-_]+)\|)(.+)$}
                      repo_prefix, repo_identifier, name = $1, $2, $3
                      repository                         = project.repositories.detect { |repo| repo.identifier == repo_identifier }
                    else
                      repository = project.repository
                    end
                    if prefix == 'commit'
                      if repository
                        @parse_changeset_visible_scope ||= Changeset.visible
                        if (changeset = @parse_changeset_visible_scope.find_by('repository_id = ? AND scmid LIKE ?', repository.id, "#{name}%"))
                          link = link_to h("#{project_prefix}#{repo_prefix}#{name}"), { :only_path => only_path, :controller => 'repositories', :action => 'revision', :id => project, :repository_id => repository.identifier_param, :rev => changeset.identifier },
                                         :class => 'changeset',
                                         :title => truncate_single_line_raw(changeset.comments, 100)
                        end
                      end
                    else
                      if repository && User.current.allowed_to?(:browse_repository, project)
                        name =~ %r{^[/\\]*(.*?)(@([^/\\@]+?))?(#(L\d+))?$}
                        path, rev, anchor = $1, $3, $5
                        link              = link_to h("#{project_prefix}#{prefix}:#{repo_prefix}#{name}"), { :only_path => only_path, :controller => 'repositories', :action => (prefix == 'export' ? 'raw' : 'entry'), :id => project, :repository_id => repository.identifier_param,
                                                                                                             :path      => to_path_param(path),
                                                                                                             :rev       => rev,
                                                                                                             :anchor    => anchor },
                                                    :class => (prefix == 'export' ? 'source download' : 'source')
                      end
                    end
                    repo_prefix = nil
                  end
                when 'attachment'
                  attachments = options[:attachments] || []
                  attachments += obj.attachments if obj.respond_to?(:attachments)
                  #only change - postet to redmine viz www.redmine.org/issues/21550
                  #call original after accept
                  is_download_link = !!options[:is_download_link]
                  if attachments && (attachment = Attachment.latest_attach(attachments, name))
                    if attachment.image?
                      link = link_to_attachment(attachment, only_path: only_path, text: thumbnail_tag(attachment, { size: 800 }))
                    else
                      link = link_to_attachment(attachment, :only_path => only_path, :download => is_download_link, :class => 'attachment')
                    end
                  end
                when 'project'
                  @parse_project_visible_scope ||= Project.visible
                  if p = @parse_project_visible_scope.find_by('identifier = :s OR LOWER(name) = :s', :s => name.downcase)
                    link = link_to_project(p, { :only_path => only_path }, :class => 'project')
                  end
                when 'user'
                  @parse_users_visible_scope ||= User.visible
                  u                          = @parse_users_visible_scope.where("LOWER(login) = :s AND type = 'User'", :s => name.downcase).first
                  link                       = link_to_user(u) if u
                else
                  if project && !prefix.nil? && (klass = prefix.classify.safe_constantize)
                    available_attributes = klass.attribute_names & ['name', 'subject', 'title', 'identifier']
                    unless available_attributes.empty?
                      plural = prefix.pluralize
                      if project.respond_to?(plural)
                        scope = project.send(plural)
                        scope = scope.visible if scope.respond_to?(:visible)
                      end
                      if scope
                        lower_name = name.downcase
                        conditions = available_attributes.map { |attr| "LOWER(#{klass.table_name}.#{attr}) = :alias_#{attr}" }.join(' OR ')
                        binds      = available_attributes.inject({}) { |h, attr| h["alias_#{attr}".to_sym] = lower_name; h }
                        entity     = scope.where(conditions, binds).first
                        link       = link_to_entity(entity, { :only_path => only_path }, { :class => prefix }) if entity
                      end
                    end
                  end
                end
              elsif sep == "@"
                name                       = remove_double_quotes(identifier)
                @parse_users_visible_scope ||= User.visible
                u                          = @parse_users_visible_scope.where("LOWER(login) = :s AND type = 'User'", :s => name.downcase).first
                link                       = link_to_user(u) if u
              end
            end
            (leading + (link || "#{project_prefix}#{prefix}#{repo_prefix}#{sep}#{identifier}#{comment_suffix}"))
          end
        end

        text.tr!("\u2236", '#')
      end

      def link_to_issue_with_easy_extensions(issue, options = {})
        return '' if issue.nil?
        title     = nil
        subject   = nil
        text      = ''
        opts_html = options.delete(:html) || {}
        if options.delete(:tracker) != false
          text << "#{issue.tracker} "
        end
        if EasySetting.value('show_issue_id', issue.project)
          text << "##{issue.id}"
        end
        if options.delete(:subject) == false
          title = issue.subject.truncate(60)
        else
          subject = issue.subject
          if truncate_length = options.delete(:truncate)
            subject = subject.truncate(truncate_length)
          end
        end
        if subject
          text << ': ' unless text.blank?
          text << subject
        end
        if issue.new_record? || !issue.visible?
          s = text
        else
          s = link_to(text, url_to_issue(issue, options), { :class => issue.css_classes, :title => title }.merge(opts_html))
        end
        s = "#{ERB::Util.h(issue.project)} - " + s if options[:project]
        s.html_safe
      end

      def progress_bar_with_easy_extensions(pcts, options = {})
        pcts    = [pcts, pcts] unless pcts.is_a?(Array)
        pcts    = pcts.collect { |i| i.to_f.floor }
        pcts[1] = pcts[1] - pcts[0]
        pcts << (100 - pcts[1] - pcts[0])
        width          = options[:width] #|| '100px;'
        legend         = options[:legend] || ''
        title          = options[:title] || "#{pcts.first} %"
        titles         = options[:titles].to_a
        titles[0]      = "#{pcts[0]}%" if titles[0].blank?
        progress_class = 'progress ' + (options[:progress_class] || '')
        progress_class << " progress-#{pcts[0]}"
        content_tag(:div,
                    content_tag('table',
                                content_tag('tr',
                                            (pcts[0] > 0 ? content_tag('td', '', :style => "width: #{pcts[0]}%;", :class => 'closed', :title => titles[0]) : ''.html_safe) +
                                                (pcts[1] > 0 ? content_tag('td', '', :style => "width: #{pcts[1]}%;", :class => 'done', :title => titles[1]) : ''.html_safe) +
                                                (pcts[2] > 0 ? content_tag('td', '', :style => "width: #{pcts[2]}%;", :class => 'todo', :title => titles[2]) : ''.html_safe)
                                ), :class => progress_class, :style => "width: #{width};", :title => title).html_safe +
                        content_tag('p', legend, :class => 'percent').html_safe,
                    :class => 'progress-parent')
      end

      def toggle_link_with_easy_extensions(name, id, options = {})
        onclick = "$('##{id}').toggle(); "
        onclick << (options[:focus] ? "$('##{options[:focus]}').focus(); " : "this.blur(); ")
        onclick << '$(document).trigger(\'erui_interface_change_vertical\');'
        onclick << "return false;"
        link_to(name, "#", { :onclick => onclick }.merge(options))
      end

      def principals_check_box_tags_with_easy_extensions(name, principals)
        s = ''
        principals.each do |principal|
          s << "<label class=\"#{principal.class.name.underscore}\">#{ check_box_tag name, principal.id, false, :id => nil }<span>#{h principal}</span></label>\n"
        end
        s.html_safe
      end

      def labelled_form_for_with_easy_extensions(*args, &proc)
        args << {} unless args.last.is_a?(Hash)
        options = args.last
        if args.first.is_a?(Symbol)
          options[:as] = args.shift
        end

        options[:html]         ||= {}
        options[:html][:class] = options[:html][:class].to_s + ' form-box'
        options[:builder]      = EasyExtensions::EasyLabelledFormBuilder
        form_for(*args, &proc)
      end

      def labelled_fields_for_with_easy_extensions(*args, &proc)
        options           = args.extract_options!
        options[:builder] = EasyExtensions::EasyLabelledFormBuilder
        fields_for(args[0], args[1], options, &proc)
      end

      # Renders the project quick-jump box
      def render_project_jump_box_with_easy_extensions
        easy_select_tag('quick_navigation', { :id => '' }, nil,
                        easy_autocomplete_path('my_projects', :jump => current_menu_item),
                        { :include_blank => true, :root_element => 'projects', :no_label_no_data => true, :force_autocomplete => true,
                          :onchange      => 'sel_val = $(\'#quick_navigation\').val(); if (sel_val != null && sel_val.length > 0) {window.location = sel_val;}',
                          :render_item   => '
              function (ul, item) {
                var content = document.createElement("a")
                content.setAttribute("href", item.id)
                content.appendChild(document.createTextNode(item.label))

                return $("<li>")
                .addClass((item.closed === true) ? "jumpbox-project-closed" : "")
                .data("item.autocomplete", item)
                .html(content)
                .appendTo(ul);
              }',
                          :html_options  => { :type => 'search', :placeholder => l(:label_jump_to_a_project), :title => l(:title_jump_to_project), :accesskey => Redmine::AccessKeys.key_for(:project_jump), :onfocus => '$(\'#quick_navigation_autocomplete\').val(\'\');' }
                        }
        )
      end

      def authorize_for_with_easy_extensions(controller, action, project = @project)
        User.current.allowed_to?({ :controller => controller, :action => action }, project)
      end

      def render_tabs_with_easy_extensions(tabs, selected = nil, options = {})
        options, selected     = selected, nil if selected.is_a?(Hash)
        selected              ||= params[:tab]
        show_tabs_if_only_one = options.key?(:show_tabs_if_only_one) ? options.delete(:show_tabs_if_only_one) : true

        if tabs.any?
          unless tabs.detect { |tab| tab[:name] == selected }
            selected = nil
          end
          selected ||= tabs.first[:name]
          if show_tabs_if_only_one || tabs.size > 1
            render :partial => 'common/tabs', :locals => options.merge(:tabs => tabs, :selected_tab => selected)
          else
            tab = tabs.first
            render :partial => tab[:partial], :locals => { :tab => tab, :selected_tab => selected }
          end
        else
          content_tag 'p', l(:label_no_data), :class => 'nodata'
        end
      end

      def body_css_classes_with_easy_extensions
        css = body_css_classes_without_easy_extensions
        css << (is_mobile_device? && ' is-mobile-device' || ' desktop-device')
        css << ' easy-mobile-view' if in_mobile_view?
        css
      end

      def context_menu_with_easy_extensions(url = nil, container = 'table.list')
        context_menu_url = url_for(url) if url
        late_javascript_tag("EASY.contextMenu.addContextMenuFor( '#{ context_menu_url }', '#{container}' )")
      end

      def sidebar_content_with_easy_extensions?
        (sidebar_content_without_easy_extensions? || content_for?(:easy_page_layout_service_box) || content_for?(:easy_page_layout_service_box_primary_actions) || content_for?(:easy_page_layout_service_box_top) || content_for?(:sidebar_exports)) && EasyExtensions.render_sidebar?(params[:controller], params[:action], params)
      end

      def thumbnail_tag_with_easy_extensions(attachment, options = {}, img_options = {})
        if self.controller.is_a?(Mailer) && File.readable?(attachment.diskfile)
          mailer                                  = self.controller
          mailer.attachments[attachment.filename] = { content: File.binread(attachment.diskfile), content_disposition: 'inline' }
          return image_tag(mailer.attachments[attachment.filename].url, { alt: attachment.filename })
        end
        if Setting.thumbnails_enabled?
          version           = if attachment.is_a?(AttachmentVersion)
                                attachment
                              else
                                current_version = attachment.current_version
                                current_version.new_record? ? attachment : current_version
                              end
          thumbnail_options = options.merge({ action: 'thumbnail', only_path: true })
          fullsrc_options   = options.merge({ download: true, only_path: true })
          image_tag(url_for(url_to_attachment(version, thumbnail_options)),
                    { :'data-fullsrc' => url_for(url_to_attachment(version, fullsrc_options)),
                      :alt            => attachment.filename }.merge(img_options))
        else
          attachment.title
        end
      end

      def include_calendar_headers_tags_with_easy_extensions
        unless @calendar_bottom_tags_included
          tags                           = ''.html_safe
          @calendar_bottom_tags_included = true
          content_for :body_bottom do
            # Redmine uses 1..7 (monday..sunday) in settings and locales
            # JQuery uses 0..6 (sunday..saturday), 7 needs to be changed to 0
            start_of_week = EasyExtensions::Calendars::Calendar.first_wday % 7

            tags << javascript_tag(
                "EASY.datepickerOptions={dateFormat: 'yy-mm-dd', firstDay: #{start_of_week}, " +
                    " onSelect: function(dateText, inst){$('#'+ inst.id).change()}," +
                    "showOn: 'button', buttonImageOnly: false, buttonText: '&#xf0679;', " +
                    "showButtonPanel: true, showWeek: false, showOtherMonths: true, " +
                    "selectOtherMonths: true, changeMonth: true, changeYear: true, beforeShow: function(){beforeShowDatePicker(arguments)}};")

            jquery_locale = current_language.to_s
            #jquery_locale = l('jquery.locale', :default => current_language.to_s)
            if jquery_locale == 'zh'
              jquery_locale = 'zh-CN'
            elsif jquery_locale == 'sr-YU'
              jquery_locale = 'sr'
            end

            unless jquery_locale == 'en'
              tags << javascript_include_tag("i18n/datepicker-#{jquery_locale}.js", defer: true)
              if jquery_locale == 'cs'
                tags << javascript_tag("EASY.schedule.require(function() {$.datepicker.regional['cs'].currentText = '#{(l(:label_today)).humanize}';$.datepicker.setDefaults($.datepicker.regional['cs']);},function(){return $.datepicker && $.datepicker.regional['cs']})")
              end
            end
            tags
          end
        end
      end

      def stylesheet_link_tag_with_easy_extensions(*sources)
        if controller && (request.format.to_s.include?('pdf') || @render_pdf)
          s       = sources.dup
          options = s.last.is_a?(Hash) ? s.pop : {}
          s.each do |source|
            if (plugin = options[:plugin])
              controller.used_stylesheets("/plugin_assets/#{plugin}/stylesheets/#{source}")
              # elsif current_theme && current_theme.stylesheets.include?(source)
              #   controller.used_stylesheets(current_theme.stylesheet_path(source))
              # elsif (asset = resolve_asset_path(source, :type => :stylesheet))
              #   controller.used_stylesheets asset
            else
              controller.used_stylesheets asset_path(source, type: :stylesheet)
            end
          end
        end

        stylesheet_link_tag_without_easy_extensions(*sources)
      end

      def format_object_with_easy_extensions(object, html = true, &block)
        value = format_object_without_easy_extensions(object, html, &block)
        easy_format_object(value, object, html)
      end

      def html_hours_with_easy_extensions(value, options = {})
        easy_html_hours(value, options)
      end

      def title_with_easy_extensions(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}

        strings = args.map do |arg|
          if arg.is_a?(Array) && arg.size >= 2
            link_to(*arg)
          else
            h(arg.to_s)
          end
        end

        if request.xhr?
          content_tag('h3', strings.join(' &#187; ').html_safe, { :class => 'title' }.merge(options))
        else
          html_title args.reverse.map { |s| (s.is_a?(Array) ? s.first : s).to_s }
          content_tag('h2', strings.join(' &#187; ').html_safe, options)
        end
      end

      # Returns the javascript tags that are included in the html layout head
      def javascript_heads_with_easy_extensions
        unless User.current.pref.warn_on_leaving_unsaved == '0'
          late_javascript_tag("warnLeavingUnsaved('#{escape_javascript l(:text_warn_on_leaving_unsaved)}');")
        end
      end

    end
  end

  module ThemesHelperPatch
    def self.included(base)
      base.class_eval do
        def current_theme_with_easy_extensions
          nil
        end

        alias_method_chain :current_theme, :easy_extensions
      end
    end
  end

end
EasyExtensions::PatchManager.register_helper_patch 'ApplicationHelper', 'EasyPatch::ApplicationHelperPatch'
EasyExtensions::PatchManager.register_helper_patch 'ApplicationHelper', 'ModalSelectorTagsHelper'
# with best hopes it will be ThemesHelper in redmine soon
EasyExtensions::PatchManager.register_helper_patch 'ApplicationHelper', 'EasyPatch::ThemesHelperPatch'
