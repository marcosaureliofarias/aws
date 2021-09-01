module EasyPatch
  module ApplicationControllerPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)
      base.class_eval do

        include EasyExtensions::Export::ExportHelper
        include ActionView::RecordIdentifier

        has_mobile_fu

        before_action :ensure_easy_attendance, :if => lambda { !request.xhr? }
        before_action :clear_used_stylesheets, :if => lambda { !(request.xhr? || api_request?) }
        before_action :force_lang

        after_action :clear_used_stylesheets, :if => lambda { !(request.xhr? || api_request?) }
        after_action :detect_iframe_from_params, :if => lambda { !(request.xhr? || api_request?) }
        after_action :ensure_context_menu_response, :only => :context_menu
        #after_action  :set_no_cache

        rescue_from ::ActionController::UnknownFormat, :with => :unknown_format
        rescue_from ::ActionController::InvalidCrossOriginRequest, :with => :csrf_error
        rescue_from ::Query::StatementInvalid, :with => :query_statement_invalid
        rescue_from ::EasyQuery::StatementInvalid, :with => :query_statement_invalid

        class_attribute :accept_anonymous_access_actions

        alias_method_chain :check_if_login_required, :easy_extensions
        alias_method_chain :find_current_user, :easy_extensions
        alias_method_chain :per_page_option, :easy_extensions
        alias_method_chain :redirect_back_or_default, :easy_extensions
        alias_method_chain :render_attachment_warning_if_needed, :easy_extensions
        alias_method_chain :render_feed, :easy_extensions
        alias_method_chain :render_api_errors, :easy_extensions
        alias_method_chain :require_login, :easy_extensions
        alias_method_chain :render_error, :easy_extensions
        alias_method_chain :parse_params_for_bulk_update, :easy_extensions
        alias_method_chain :filename_for_content_disposition, :easy_extensions

        def self.accept_anonymous_access(*actions)
          if actions.any?
            self.accept_anonymous_access_actions = actions
          else
            self.accept_anonymous_access_actions || []
          end
        end

        def accept_anonymous_access?(action = action_name)
          self.class.accept_anonymous_access.include?(action.to_sym)
        end

        def easy_page_context
          @__easy_page_ctx
        end

        def clear_used_stylesheets
          @used_stylesheets = []
        end

        def used_stylesheets(s = nil)
          @used_stylesheets ||= []
          if s.nil?
            @used_stylesheets
          else
            @used_stylesheets << s unless @used_stylesheets.include?(s)
          end
        end

        def current_user_ip
          request.env['HTTP_X_FORWARDED_FOR'].blank? ? request.remote_ip : request.env['HTTP_X_FORWARDED_FOR'].to_s.split(',').first
        end

        def parse_params_for_bulk_entity_attributes(entity_params = nil)
          return {} if entity_params.nil?
          entity_params = entity_params.to_unsafe_hash if entity_params.respond_to?(:to_unsafe_hash)
          attributes    = (entity_params).reject { |k, v| v.blank? }
          attributes.each_key { |k| attributes[k] = '' if attributes[k] == 'none' }
          if custom = attributes['custom_field_values']
            custom.reject! { |k, v| v.blank? }
            custom.each_key do |k|
              if custom[k].is_a?(Array)
                custom[k] << '' if custom[k].delete('__none__')
              else
                custom[k] = '' if custom[k] == '__none__'
              end
            end
          end
          attributes
        end

        # Rescues an invalid query statement. Just in case...
        def query_statement_invalid(exception)
          logger.error "Query::StatementInvalid: #{exception.message}" if logger
          sort_clear if respond_to?(:sort_clear)
          render_error l(:label_error_query)
        end

        def render_api_error(msg)
          @error_messages = Array(msg)
          render :template => 'common/error_messages.api', :status => :unprocessable_entity, :layout => nil
        end

        def require_admin_or_lesser_admin(area_name)
          return unless require_login

          if !User.current.easy_lesser_admin_for?(area_name)
            render_403
            return false
          end

          true
        end

        def require_admin_or_api_request_or_lesser_admin(area_name = nil)
          return true if api_request?
          if User.current.easy_lesser_admin_for?(area_name)
            true
          elsif User.current.logged?
            render_406
          else
            deny_access
          end
        end

        protected

        # by default permissions are checked on layout action, override if you want to use your own
        def edit_layout_action
          'layout'
        end

        def count_time(&block)
          start_time = Time.now
          yield
          logger.info(Time.now - start_time)
        end

        def content_types_for_disabled_cache
          @content_types_for_disabled_cache ||= ['', Redmine::MimeType::EXTENSIONS['html']]
          @content_types_for_disabled_cache
        end

        def set_no_cache
          if content_types_for_disabled_cache.include?(response.content_type.to_s)
            response.headers['Cache-Control'] = 'no-cache, no-store, max-age=0, must-revalidate'
            response.headers['Pragma']        = 'no-cache'
          end
        end

        # Marks current action to be rendered as easy page with custom layout.
        # There is three modes for customizing modules.
        # => user is user, entity_id is nil - My Page. Each user can customize the page.
        # => user is nil, entity id is integer - Project Page. Each project has a different page that is the same for all users.
        # => user is user, entity id is integer - Each entity page has a different page that is customizable for each user.
        # Params:
        # => page - EasyPage instance to be rendered
        # => user - determines which page modules will be loaded. If the user is nil than it means that the page has no dependency on user.
        # => entity_id - it is any ID for resolution of the current Page (e.g. 31 for Project ID 31, nil for the My Page)
        # => back_url - url for redirecting back
        # => edit - true / false. If true, the page is rendered in edit mode.
        # => page_context - additional informations about page. E.g. :project if project_controller
        def render_action_as_easy_page(page, user = nil, entity_id = nil, back_url = nil, edit = false, page_context = {})
          return false unless page.is_a?(EasyPage)

          raise StandardError, "No zones defined for a page: #{page.page_name}" if !page.zones.exists?
          @page_editable = page_context.delete(:page_editable)
          @page_editable = User.current.allowed_to_globally?({ :controller => self.controller_name, :action => edit_layout_action }) if @page_editable.nil?

          page_params  = create_page_params_for_easy_page(page, user, entity_id, back_url, edit, @page_editable, page_context)
          page_tab     = page_params[:current_tab]
          page_modules = page.user_tab_modules(page_tab, user, entity_id)
          page_context ||= {}

          @easy_page_modules_data = {}
          add_global_filters_to_page_context!(page_context, page_tab)

          page_params[:gridstack] = {}
          page_modules.each do |zone_name, page_modules_in_zone|
            page_modules_in_zone.each do |page_module|
              if page_module.snapshot? && !page_module.snapshot_initialized?
                flash.now[:error] = l(:error_page_module_snapshot_not_initialized, module_name: page_module.module_definition.translated_name, query_name: page_module.settings['query_name'])
              end

              settings = params[page_module.module_name]
              user     = user || User.current

              if edit
                @easy_page_modules_data[page_module.module_name] = page_module.get_edit_data(user, settings, page_context)
              else
                @easy_page_modules_data[page_module.module_name] =
                    if params[:page_module_force_reload] != '1' && page_module.cache_on? && Rails.cache.exist?(page_module.module_cache_key(user))
                      {}
                    else
                      page_module.get_show_data(user, settings, page_context)
                    end
              end
              page_params[:gridstack][page_module.uuid] = page_module.settings['gridstack']
            end
          end
          @__easy_page_ctx = { :page_modules => page_modules, :page_params => page_params, :layout_style => page.layout_path }
          @layout_style    = page.layout_path
          render layout: 'easy_page_layouts/easy_page'

          true
        end

        # Marks current action to be rendered as easy page template with custom layout.
        # There is three modes for customizing modules.
        # => user is user, entity_id is nil - My Page. Each user can customize the page.
        # => user is nil, entity id is integer - Project Page. Each project has a different page that is the same for all users.
        # => user is user, entity id is integer - Each entity page has a different page that is customizable for each user.
        # Params:
        # => page_template - EasyPageTemplate instance to be rendered
        # => user - determines which page modules will be loaded. If the user is nil than it means that the page has no dependency on user.
        # => entity_id - it is any ID for resolution of the current Page (e.g. 31 for Project ID 31, nil for the My Page)
        # => back_url - url for redirecting back
        # => edit - true / false. If true, the page is rendered in edit mode.
        # => page_context - additional informations about page. E.g. :project if project_controller
        def render_action_as_easy_page_template(page_template, user = nil, entity_id = nil, back_url = nil, edit = false, page_context = {})
          return false unless page_template.is_a?(EasyPageTemplate)
          page = page_template.page_definition

          raise StandardError, "No zones defined for a page: #{page.page_name}" if !page.zones.exists?
          @page_editable = page_context.delete(:page_editable)
          @page_editable = User.current.allowed_to_globally?({ :controller => self.controller_name, :action => edit_layout_action }) if @page_editable.nil?

          page_params           = create_page_params_for_easy_page_template(page_template, page, user, entity_id, back_url, edit, @page_editable)
          page_tab              = page_params[:current_tab]
          page_template_modules = page_template.template_tab_modules(page_tab, entity_id)

          @easy_page_modules_data = {}

          page_params[:gridstack] = {}
          page_template_modules.each do |zone_name, page_template_modules_in_zone|
            page_template_modules_in_zone.each do |page_template_module|
              if edit
                @easy_page_modules_data[page_template_module.module_name] = page_template_module.get_edit_data(user, params[page_template_module.module_name], page_context)
              else
                @easy_page_modules_data[page_template_module.module_name] = page_template_module.get_show_data(user, params[page_template_module.module_name], page_context)
              end
              page_params[:gridstack][page_template_module.uuid] = page_template_module.settings['gridstack']
            end
          end

          @__easy_page_ctx = { :page_modules => page_template_modules, :page_params => page_params, :layout_style => page.layout_path }

          @layout_style = page.layout_path
          render layout: 'easy_page_layouts/easy_page'

          true
        end

        # Marks current action to be rendered as easy page template tab with custom layout.
        # There is three modes for customizing modules.
        # => user is user, entity_id is nil - My Page. Each user can customize the page.
        # => user is nil, entity id is integer - Project Page. Each project has a different page that is the same for all users.
        # => user is user, entity id is integer - Each entity page has a different page that is customizable for each user.
        # Params:
        # => page_template - EasyPageTemplate instance to be rendered
        # => user - determines which page modules will be loaded. If the user is nil than it means that the page has no dependency on user.
        # => entity_id - it is any ID for resolution of the current Page (e.g. 31 for Project ID 31, nil for the My Page)
        # => edit - true / false. If true, the page is rendered in edit mode.
        # => page_context - additional informations about page. E.g. :project if project_controller
        def render_action_as_easy_tab_content(page_tab, page, user = nil, entity_id = nil, back_url = nil, edit = false, page_context = {})
          if page.is_a?(EasyPageTemplate)
            page_template = page
            page          = page_template.page_definition
          end
          return false unless page.is_a?(EasyPage)

          raise StandardError, "No zones defined for a page: #{page.page_name}" if !page.zones.exists?

          tab = page_tab.position
          if page_tab.is_a?(EasyPageUserTab)
            page_params  = create_page_params_for_easy_page(page, user, entity_id, back_url, edit)
            page_modules = page.user_tab_modules(page_tab, user, entity_id)
          elsif page_tab.is_a?(EasyPageTemplateTab)
            page_params  = create_page_params_for_easy_page_template(page_template, page, user, entity_id, back_url, edit)
            page_modules = page_template.template_tab_modules(page_tab, entity_id)
          end

          @easy_page_modules_data = {}
          add_global_filters_to_page_context!(page_context)

          page_modules.each do |zone_name, page_modules_in_zone|
            page_modules_in_zone.each do |page_module|
              if edit
                @easy_page_modules_data[page_module.module_name] = page_module.get_edit_data(user || User.current, params[page_module.module_name], page_context)
              else
                @easy_page_modules_data[page_module.module_name] = page_module.get_show_data(user || User.current, params[page_module.module_name], page_context)
              end
            end
          end

          @__easy_page_ctx = { :page_modules => page_modules, :page_params => page_params, :layout_style => page.layout_path }
          @layout_style    = page.layout_path

          true
        end

        def add_global_filters_to_page_context!(page_context, page_tab = nil)
          active_global_filters = {}

          no_filters = true
          params.each do |key, value|
            if key.start_with?('global_filter_') && key =~ /\Aglobal_filter_(\d+)\Z/
              active_global_filters[$1] = value
              no_filters                = false
            end
          end

          if no_filters && page_tab
            filters = page_tab.settings['global_filters'] || {}
            filters.each do |id, options|
              if (value = options['default_value'].presence)
                active_global_filters[id] = value
              end
            end
          end

          if params['global_currency'].blank?
            currency = page_tab && page_tab.settings['global_currency_defaults']
          else
            currency = params['global_currency']
          end

          if currency && EasyCurrency.activated.where(iso_code: currency).exists?
            page_context[:active_global_currency] = currency
          end

          page_context[:active_global_filters] = active_global_filters
        end

        def create_page_params_for_easy_page(page, user = nil, entity_id = nil, back_url = nil, edit = false, page_editable = true, page_context = {})
          raise ArgumentError, 'User have to be a user.' if user && !user.is_a?(User)

          user_id    = user&.id
          project_id = params[:project_id] || page_context[:project]&.id
          tabs       = EasyPageUserTab.page_tabs(page, user_id, entity_id)
          { page:              page, user: user, user_id: user_id, page_editable: page_editable, gridstack: {}, entity_id: entity_id, back_url: back_url, edit: edit, inline_view: params[:inline_view], inline_edit: params[:inline_edit], modal_edit: params[:modal_edit], tabs: tabs, current_tab: get_selected_page_tab(tabs),
            url_order_module:  { controller: 'easy_page_layout', action: 'order_module', page_id: page.id, user_id: user_id, entity_id: entity_id, project_id: project_id },
            url_add_module:    { controller: 'easy_page_layout', action: 'add_module', page_id: page.id, user_id: user_id, entity_id: entity_id, project_id: project_id },
            url_clone_module:  { controller: 'easy_page_layout', action: 'clone_module', page_id: page.id, user_id: user_id, entity_id: entity_id, project_id: project_id },
            url_remove_module: { controller: 'easy_page_layout', action: 'remove_module', page_id: page.id, user_id: user_id, entity_id: entity_id, project_id: project_id },
            url_save_modules:  { controller: 'easy_page_layout', action: 'save_module', page_id: page.id, user_id: user_id, entity_id: entity_id, project_id: project_id } }
        end

        def create_page_params_for_easy_page_template(page_template, page, user = nil, entity_id = nil, back_url = nil, edit = false, page_editable = true)
          raise ArgumentError, 'User have to be a user.' if user && !user.is_a?(User)

          user_id = user&.id
          tabs    = EasyPageTemplateTab.page_template_tabs(page_template, entity_id)
          { page_template:     page_template, page: page, user: user, user_id: user_id, page_editable: page_editable, gridstack: {}, entity_id: entity_id, back_url: back_url, edit: edit, inline_view: params[:inline_view], inline_edit: params[:inline_edit], modal_edit: params[:modal_edit], tabs: tabs, current_tab: get_selected_page_tab(tabs),
            url_order_module:  { controller: 'easy_page_template_layout', action: 'order_module', id: page_template.id, entity_id: entity_id },
            url_add_module:    { controller: 'easy_page_template_layout', action: 'add_module', id: page_template.id, entity_id: entity_id },
            url_clone_module:  { controller: 'easy_page_template_layout', action: 'clone_module', id: page_template.id, entity_id: entity_id },
            url_remove_module: { controller: 'easy_page_template_layout', action: 'remove_module', id: page_template.id, entity_id: entity_id },
            url_save_modules:  { controller: 'easy_page_template_layout', action: 'save_module', id: page_template.id, entity_id: entity_id } }
        end

        def render_single_easy_page_module(page_module, page_module_render_settings = nil, page = nil, user = nil, entity_id = nil, back_url = nil, edit = nil, with_container = false, page_context = {})
          partial, locals = prepare_render_for_single_easy_page_module(page_module, page_module_render_settings, page, user, entity_id, back_url, edit, with_container, page_context)

          render :partial => partial, :locals => locals
        end

        def prepare_render_for_single_easy_page_module(page_module, page_module_render_settings = nil, page = nil, user = nil, entity_id = nil, back_url = nil, edit = nil, with_container = false, page_context = {})
          raise ArgumentError, 'The page_module variable have to be a EasyPageZoneModule or EasyPageTemplateModule' if !page_module.is_a?(EasyPageZoneModule) && !page_module.is_a?(EasyPageTemplateModule)
          page      ||= page_module.page_definition
          user      ||= page_module.user if page_module.is_a?(EasyPageZoneModule)
          user      ||= User.current

          back_url  = params[:back_url] if back_url.nil?
          entity_id = params[:entity_id] if entity_id.nil?
          add_global_filters_to_page_context!(page_context)

          if edit.nil?
            edit = false
            edit = params[:edit] if params.key?(:edit)
            edit = params[:inline_edit] if params.key?(:inline_edit)
            edit = params[:modal_edit] if params.key?(:modal_edit)
          end

          if page_module_render_settings.nil?
            if edit
              page_module_render_settings = page_module.get_edit_data(user, params[page_module.module_name], page_context)
            else
              page_module_render_settings = page_module.get_show_data(user, params[page_module.module_name], page_context)
            end
          end

          page_params = if page_module.is_a?(EasyPageTemplateModule)
                          create_page_params_for_easy_page_template(page, nil, user, entity_id, back_url, edit)
                        else
                          create_page_params_for_easy_page(page, user, entity_id, back_url, edit)
                        end

          @easy_page_modules_data                          ||= {}
          @easy_page_modules_data[page_module.module_name] = page_module_render_settings || {}

          partial = "easy_page_layout/page_module_#{edit ? 'edit' : 'show'}#{with_container ? '_container' : ''}"
          locals  = { :page_params => page_params, :page_module => page_module }

          return partial, locals
        end

        def loading_group?
          request.xhr? && !!loading_group
        end

        def loading_group
          if params[:group_to_load].respond_to?(:values)
            params[:group_to_load].values
          else
            params[:group_to_load]
          end
        end

        def loading_multiple_groups?(query = nil)
          query ||= @query
          loading_group? && (loading_group.is_a?(Array) && loading_group.first.is_a?(Array))
        end

        def ensure_easy_attendance
          EasyAttendance.create_arrival(User.current, current_user_ip) if !request.xhr? && [nil, 'html', 'mobile'].include?(request.format)
        end

        def set_pagination(query = nil, options = {})
          return @entity_pages if @entity_pages
          query ||= @query
          case params[:format]
          when 'csv', 'pdf', 'ics', 'xlsx'
            @limit = Setting.issues_export_limit.to_i
          when 'atom'
            @limit = Setting.feeds_limit.to_i
          when 'xml', 'json'
            @offset, @limit = api_offset_and_limit
          else
            @limit = options.key?(:limit) ? options[:limit] : per_page_option
          end

          if ['xml', 'json'].include?(params[:format])
            @entity_count = query.entity_count(options)
            @entity_pages = Redmine::Pagination::Paginator.new @entity_count, @limit, params[:page]
          else
            unless loading_group?
              @entity_count = query.entity_count(options)
              objects_count = if query.grouped?
                                query.groups_count(options)
                              elsif query.display_as_tree? && query.display_as_tree_with_expander_on_root
                                (query.use_visible_condition? ? Project.visible : Project).
                                    where(Project.arel_table[:parent_id].eq(nil).to_sql).where(query.statement).count +
                                    query.children_scope.distinct(:id).map(&:id).count # with children
                              else
                                @entity_count
                              end
              @entity_pages = Redmine::Pagination::Paginator.new objects_count, @limit, params[:page]
            end
          end
        end

        # Prepare variable @entities, @entity_pages, also sets @offset, @order and @limit variables
        # @param query[EasyQuery] optional argument fallback to @query
        # @param options[Hash] optional argument with sql options, if not given, defaults to {order: sort_clause, limit: @limit, offset: @offset}
        # @return entities to render or nil if there is no next page to render
        def prepare_easy_query_render(query = nil, options = {})
          query ||= @query

          entity_pages = set_pagination(query, options)

          return if (request.xhr? && entity_pages && entity_pages.last_page.to_i < params['page'].to_i) || (request.format.html? && !query.outputs.include?('list'))

          # used even there is a multiple groups. hope it all loaded at same page :)
          options[:order]  ||= sort_clause if sort_criteria
          options[:limit]  ||= @limit
          options[:offset] ||= (@offset || (entity_pages && entity_pages.offset) || (((params[:page] || 1).to_i - 1) * options[:limit].to_i))

          if query.grouped? && !params[:easy_query_q]
            if api_request? || %w(ics atom vcf).include?(params[:format])
              @entities = query.entities(options)
            elsif %w(pdf csv xlsx).include?(params[:format])
              @entities = query.prepare_export_result(options)
            else
              if loading_multiple_groups?(query)
                @entities = Hash.new
                loading_group.each { |group| @entities[group] = query.entities_for_group(group, options).to_a }
              elsif loading_group?
                @entities = query.entities_for_group(loading_group, options)
              else
                @groups = @entities = query.groups(options)
              end
            end
          else
            case params[:format]
            when 'pdf', 'csv', 'xlsx'
              @entities = query.prepare_export_result(options)
            else
              @entities = query.entities(options)
            end
          end

          @entities
        end

        # Renders easy query
        # @param query[EasyQuery] optional argument fallback to @query
        # @param action[String] optional argument fallback to 'index'
        def render_easy_query_html(query = nil, action = nil, locals = {})
          query ||= @query

          if request.xhr? && @entity_pages && @entity_pages.last_page.to_i < params[:page].to_i
            render_404
            return false
          end

          locals_options = params[:view_options] || {}
          # On view is default 30 but some queries have 25
          locals_options[:group_limit] ||= @limit
          locals_options[:group_limit] = locals_options[:group_limit].to_i if locals_options[:group_limit] != 'all'
          locals                       = { easy_query: query, entities: @entities, options: locals_options }.merge(locals)

          if request.xhr? && params[:easy_query_q]
            render partial: 'easy_queries/easy_query_entities_list', locals: locals
          elsif loading_group?
            render_options = { partial: 'easy_queries/easy_query_entities', locals: locals }
            if @entities.is_a?(Hash)
              groups = Hash.new
              @entities.each do |group, entities|
                render_options[:locals][:entities] = entities
                groups[group]                      = render_to_string render_options
              end
              render json: groups
            else
              render render_options
            end
          elsif request.xhr? && (params[:modal] != '1') # next page by infinity
            render partial: 'easy_queries/easy_query_entities_list', locals: locals.merge(entity_pages: @entity_pages, entity_count: @entity_count)
          else
            render action: action
          end
        end

        def render_easy_query_xlsx(options = {})
          query    = options[:query] || @query
          title    ||= options[:title] || l("label_#{query.entity.name.pluralize.underscore}", default: 'Xlsx export')
          filename = get_export_filename(:xlsx, query, options[:filename] || title)
          send_file_headers! type: Redmine::MimeType.of(filename), filename: filename
          render 'common/easy_query_index', locals: { default_title: title }
        end

        def render_easy_query_pdf(options = {})
          query = options[:query] || @query
          title ||= options[:title] || l("label_#{query.entity.name.pluralize.underscore}", default: 'Pdf export')
          send_file_headers! :type => 'application/pdf', :filename => get_export_filename(:pdf, @query, options[:filename] || title)
          render 'common/easy_query_index', locals: { default_title: title }
        end

        def render_easy_query(options = {}, &respond_to)
          if request.xhr? && !@entities
            render_404
            return false
          end

          query       = options[:query] || @query
          entity_name = query.entity.name.pluralize.underscore
          title       = options[:title] || l("label_#{entity_name}", default: l("heading_#{entity_name}_index"))
          pdf_title   = options[:pdf_title] || options[:export_title] || title
          csv_title   = options[:csv_title] || options[:export_title] || get_export_filename(:csv, @query, title)
          xlsx_title  = options[:xlsx_title] || options[:export_title] || title

          if options[:before_render].is_a?(Proc)
            instance_eval(&options[:before_render])
          end

          respond_to do |format|
            format.html { render_easy_query_html(query, options[:action], options[:html_locals] || {}) }
            format.csv { send_data(export_to_csv(@entities, @query), filename: csv_title) }
            format.pdf { render_easy_query_pdf(query: query, filename: title, title: pdf_title) }
            format.xlsx { render_easy_query_xlsx(query: query, filename: title, title: xlsx_title) }
            format.api do
              headers['Total']    = @entity_count
              headers['Per-Page'] = @limit
            end
          end
        end

        def index_for_easy_query(entity_klass, default_sort = [], options = {}, &respond_to)
          retrieve_query(entity_klass)

          options[:query] = @query

          sort_init(@query.sort_criteria.presence || @query.default_sort_criteria.presence || default_sort)
          sort_update(@query.sortable_columns)

          prepare_easy_query_render(@query, options)

          render_easy_query(options, &respond_to)
        end

        def find_optional_project_by_project_id
          @project = Project.find(params[:project_id]) unless params[:project_id].blank?
        rescue ActiveRecord::RecordNotFound
          render_404
        end

        # change_url_params('http://d.com?t=5') { |p| p['t'] = 6;} => http://d.com?t=6
        def change_url_params(url, &block)
          uri = URI.parse(url.to_s)
          p   = Rack::Utils.parse_nested_query(uri.query)
          yield(p)
          uri.query = p.to_query
          uri.to_s
        end

        def change_url_params!(url, &block)
          url.replace(change_url_params(url, &block))
        end

        def ensure_context_menu_response
          response.body = (render_to_string partial: 'context_menus/context_menu_empty') if Loofah::Helpers.strip_tags(response.body).squish.blank?
        end

        protected

        def find_current_user_alternative
          nil
        end

        private

        def detect_iframe_from_params
          if params[:load_iframe].present?
            session[:in_iframe] = params[:load_iframe].to_boolean
          end
          User.current.in_iframe = !!session[:in_iframe]
        end

        def detect_content_type(attachment)
          content_type = attachment.content_type
          if content_type.blank? || content_type == "application/octet-stream"
            content_type = Redmine::MimeType.of(attachment.filename)
          end
          content_type.presence || "application/octet-stream"
        end

        def get_selected_page_tab(tabs)
          return nil if tabs.blank?
          selected_tab = nil

          tabs.each do |tab|
            if params[:tab_id] && tab.id == params[:tab_id].to_i
              selected_tab = tab
              break
            elsif params[:t] && tab.position == params[:t].to_i
              selected_tab = tab
              break
            end
          end

          if !selected_tab && in_mobile_view?
            selected_tab = tabs.find(&:mobile_default?)
          end

          selected_tab || tabs.first
        end

        def copy_time_entry_settings(entity_params, saved_projects)
          if entity_params && entity_params[:inherit_time_entry_activities].to_s.to_boolean
            saved_projects.each do |project|
              project.inherit_time_entry_activities = true
              project.copy_time_entry_activities_from_parent
            end
          end
        end

        def force_lang
          set_language_if_valid(params[:force_lang]) if !params[:force_lang].blank?
          return true
        end

        def unknown_format
          render_406
        end

        def csrf_error(exception)
          if Rails.application.config.consider_all_requests_local
            raise exception
          else
            self.response_body = nil
            head 400
          end
        end

        def render_406(options = {})
          render_error({ :message => :notice_not_acceptable, :status => 406 }.merge(options))
          return false
        end

        def automat_api_request?
          api_request? && User.current.id == 88
        end

      end
    end

    module InstanceMethods

      def parse_params_for_bulk_update_with_easy_extensions(params)
        attributes = (params || {}).reject { |_, v| v.blank? }
        if custom = attributes[:custom_field_values]
          custom.reject! do |_, v|
            v.blank? ||
                v == [''] ||
                ((v.is_a?(ActionController::Parameters) || v.is_a?(Hash)) && v['date'] == '') # datetime
          end
        end
        parse_params_for_bulk_update_without_easy_extensions(attributes)
      end

      def filename_for_content_disposition_with_easy_extensions(name)
        /Safari/.match?(request.env['HTTP_USER_AGENT']) ? ERB::Util.url_encode(name) : filename_for_content_disposition_without_easy_extensions(name)
      end

      def find_current_user_with_easy_extensions
        user = nil

        if session[:user_id]
          # existing session
          user = (User.active.find(session[:user_id]) rescue nil)
        end
        if user.nil? && !api_request?
          if autologin_user = try_to_autologin
            user = autologin_user
          elsif params[:format] == 'atom' && params[:key] && request.get? && accept_rss_auth?
            # RSS key authentication does not start a session
            user = User.find_by_rss_key(params[:key])
          end
        end

        user ||= find_current_user_alternative

        if user.nil? && Setting.rest_api_enabled? && accept_api_auth?
          if (key = api_key_from_request)
            # Use API key
            user = User.find_by_api_key(key)
          elsif /\ABasic /i.match?(request.authorization.to_s)
            # HTTP Basic, either username/password or API key/random
            authenticate_with_http_basic do |username, password|
              user = User.try_to_login(username, password) || User.find_by_api_key(username)
            end
            if user && user.must_change_password?
              render_error :message => 'You must change your password', :status => 403
              return
            end
          end
          # Switch user if requested by an admin user
          if user && user.admin? && (username = api_switch_user_from_request)
            su = User.find_by_login(username)
            if su && su.active?
              logger.info(" User switched by: #{user.login} (id=#{user.id})") if logger
              user = su
            else
              render_error :message => 'Invalid X-Redmine-Switch-User header', :status => 412
            end
          end
        end
        # store current ip address in user object ephemerally
        user.remote_ip = request.remote_ip if user
        user
      end

      def require_login_with_easy_extensions
        if !User.current.logged?
          # Extract only the basic url parameters on non-GET requests
          if request.get?
            url = CGI.unescape(request.original_url)
          else
            url = url_for(controller: params[:controller], action: params[:action], id: params[:id], project_id: params[:project_id])
          end

          if EasyExtensions::IdentityProviders.current
            redirect_to EasyExtensions::IdentityProviders.current.login_path(back_url: params[:back_url])

            return false
          elsif EasyExtensions::Sso.enabled?
            redirect_to sso_autologin_path(back_url: url)

            return false
          end

          respond_to do |format|
            format.html {
              if request.xhr?
                head :unauthorized
              else
                redirect_to signin_path(back_url: url)
              end
            }
            format.any(:atom, :pdf, :csv) {
              redirect_to signin_path(back_url: url)
            }
            format.api do
              if Setting.rest_api_enabled? && accept_api_auth?
                head(:unauthorized, 'WWW-Authenticate' => 'Basic realm="Redmine API"')
              else
                head(:forbidden)
              end
            end
            format.js   { head :unauthorized, 'WWW-Authenticate' => 'Basic realm="Redmine API"' }
            format.any  { head :unauthorized }
          end

          return false
        end

        return true
      end

      def render_feed_with_easy_extensions(items, options = {})
        @items = items || []
        @items.sort_by!(&:event_datetime)
        @items.reverse!
        @items = @items.slice(0, Setting.feeds_limit.to_i)
        @title = options[:title] || Setting.app_title
        render :template => (options[:template] || 'common/feed'), :formats => [:atom], :layout => false, :content_type => 'application/atom+xml'
      end

      def render_error_with_easy_extensions(arg)
        arg = { :message => arg } unless arg.is_a?(Hash)

        @message = arg[:message]
        @message = l(@message) if @message.is_a?(Symbol)
        @status  = arg[:status] || 500

        respond_to do |format|
          format.html {
            render :template => 'common/error', :layout => use_layout, :status => @status
          }
          format.js {
            render :status => @status, :plain => "alert(\"#{@status}: #{@message}\")"
          }
          format.api { @error_messages = [@message]; render :template => 'common/error_messages.api', :status => @status }
          format.any { head @status }
        end
      end

      def render_attachment_warning_if_needed_with_easy_extensions(obj)
        if obj.unsaved_attachments.present?
          flash[:warning] = l(:warning_attachments_not_saved, obj.unsaved_attachments.size)
          obj.unsaved_attachments.each do |att|
            att.errors.each do |attribute, err|
              flash[:warning] = attribute == :description ? "#{l(:field_description)} #{err}" : err
            end
          end
        end
      end

      def per_page_option_with_easy_extensions
        if params[:per_page] && params[:per_page] == 'all'
          nil
        else
          per_page_option_without_easy_extensions
        end
      end

      def render_api_errors_with_easy_extensions(*messages)
        messages = messages.flatten

        logger.info 'API ERROR:'
        logger.info messages

        render_api_errors_without_easy_extensions(*messages)
      end

      def redirect_back_or_default_with_easy_extensions(default, options = {})
        back_url = Addressable::URI.escape(params[:back_url2].to_s) if params[:back_url2]
        if back_url.present? && (valid_url = validate_back_url(back_url))
          redirect_to(valid_url)
          return
        end
        if params[:back_url].present?
          params[:back_url] = params[:back_url].is_a?(Hash) ? url_for(params[:back_url]) : Addressable::URI.escape(params[:back_url])
        end
        redirect_back_or_default_without_easy_extensions(default, options)
      end

      def check_if_login_required_with_easy_extensions
        if !accept_anonymous_access?
          check_if_login_required_without_easy_extensions
        end
      end

    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'ApplicationController', 'EasyPatch::ApplicationControllerPatch'
