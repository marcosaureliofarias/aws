module EasyExtensions
  module EasyQueryHelpers
    class EasyQueryPresenter < EasyQueryAdapterPresenter

      # --- GETTERS ---
      attr_accessor :loading_group, :page_module, :row_limit, :export_formats

      def default_render_options
        { hide_sums_in_group_by: true }
      end

      def initialize(query, view_context = nil, options = {})
        options[:options] ||= {}
        options[:options].reverse_merge!(default_render_options)
        super(query, view_context, options)
        @page_module = options[:page_module]

        @export_formats        = ActiveSupport::OrderedHash.new
        @export_formats[:csv]  = {}
        @export_formats[:pdf]  = {}
        @export_formats[:xlsx] = {}
      end

      def entities(options = {})
        # can not fetch, cuz gantt is fetching instead of nil
        # TODO: gantt should be output!
        @entities ||= @options[:entities] || h.instance_variable_get(:@entities) || (options.delete(:fetch) && model.entities(options))
      end

      def entity_count(options = {})
        @entity_count ||= h.instance_variable_get(:@entity_count) || model.entity_count(options)
      end

      def entity_pages
        @options[:entity_pages] || h.instance_variable_get(:@entity_pages)
      end

      def display_save_button
        true
      end


      # ----- RENDERING HELPERS ----

      def default_name
        h.l(self.class.name.underscore, :scope => [:easy_query, :name])
      end

      def name
        @name ||= options[:easy_query_name] || (model.new_record? ? default_name : model.name)
      end

      def groups_url
        options[:groups_url] || { params: request.query_parameters.except('group_to_load') }
      end

      def show_free_search?
        options.key?(:show_free_search) ? options[:show_free_search] : options[:page_module].nil? && model.searchable_columns.any?
      end

      def has_contextmenu?
        options[:options][:hascontextmenu].to_s == 'true'
      end

      def display_columns_select?(action = 'edit')
        true
      end

      def display_sort_options?(action = 'edit')
        action == 'edit' ? true : false
      end

      def display_group_by_select?(action = 'edit')
        true
      end

      def display_settings?(action)
        true
      end

      def has_default_filter?
        model.filters == model.default_filter
      end

      def render_zoom_links?
        (outputs.list? && group_by_column && group_by_column.date?) || render_zoom_listing_links? || report_grouped_by_date?
      end

      def render_zoom_listing_links?
        (outputs.chart? && (model.chart_grouped_by_date_column? || !model.chart_settings['period_column'].blank?)) || model.period_columns?
      end

      def report_grouped_by_date?
        outputs.report? && model.settings['report_group_by'].is_a?(Array) && model.groupable_columns.detect { |c| model.settings['report_group_by'].include?(c.name.to_s) && c.date? }
      end

      def use_strict_shift?
        outputs.output_enabled?('chart') && model.chart_settings['period_column'].present? && model.chart_settings['period_column'] != model.chart_settings['axis_x_column']
      end

      def switch_period_url(zoom, path_method = :url_for, url_params = {}, block_name = nil)
        period_params = {
            outputs:                 model.outputs,
            period_date_period_type: '2',
        }
        if use_strict_shift?
          period_params[:period_zoom] = zoom
        else
          period_params[:period_start_date]  = model.period_start_date
          period_params[:switch_period_zoom] = zoom
        end
        h.send(path_method, url_params.deep_merge(block_name.blank? ? period_params : { block_name => period_params }))
      end

      def shifted_period_dates(shift)
        start_date = model.period_start_date
        end_date = model.period_end_date
        if use_strict_shift?
          {
              period_start_date: model.beginning_of_period_zoom(start_date + period_zoom_shift(shift) + 1),
              period_end_date:   model.end_of_period_zoom(end_date + period_zoom_shift(shift) - 1)
          }
        else
          gap = end_date - start_date

          # no 29 February in current `year` period && new period contains 29 February
          if gap == 364 && (start_date.advance(years: shift).leap? && start_date.yday < 60 ||
                            end_date.advance(years: shift).leap? && end_date.yday > 58)
            gap += 2
          elsif gap != 365 # current period `year` contains 29 February
            gap += 1
          end
          if shift < 0
            {
                period_start_date: start_date - (gap * (-1 * shift)),
                period_end_date:   start_date - 1.day
            }
          else
            {
                period_start_date: end_date + 1.day,
                period_end_date:   end_date + (gap * shift)
            }
          end
        end
      end

      def shifted_period_url(shift, path_method = :url_for, url_params = {}, block_name = nil)
        period_params = {
            outputs:                 model.outputs,
            period_date_period_type: '2',
            period_zoom:             model.period_zoom
        }.merge(shifted_period_dates(shift))
        h.send(path_method, url_params.deep_merge(block_name.blank? ? period_params : { block_name => period_params }))
      end

      def previous_period_url(path_method = :url_for, url_params = {}, block_name = nil)
        shifted_period_url(-1, path_method, url_params, block_name)
      end

      def next_period_url(path_method = :url_for, url_params = {}, block_name = nil)
        shifted_period_url(1, path_method, url_params, block_name)
      end

      def period_calendar_url(path_method = :url_for, url_params = {}, block_name = nil)
        period_params = {
            outputs:                 model.outputs,
            period_date_period_type: '2',
            period_zoom:             model.period_zoom
        }
        h.send(path_method, url_params.deep_merge(block_name.blank? ? period_params : { block_name => period_params }))
      end


      def to_model
        self
      end

      def model_name
        EasyQuery.model_name
      end

      def to_partial_path
        'easy_queries/easy_query'
      end

      def block_name
        options[:block_name] || (page_module ? page_module.page_zone_module.module_name : nil)
      end

      def modul_uniq_id
        options[:modul_uniq_id] || ''
      end

      def render_zoom_links
        return unless render_zoom_links?
        # TODO: it should give a presenter itself to the partial and there decide what and how to render
        locals = { :base_url => {}, :block_name => self.page_module.page_zone_module.module_name } if self.page_module
        h.render(:partial => 'easy_queries/zoom_links', :locals => { :query => self, :presenter => self }.merge(locals || {}))
      end

      def entity_list(entities = self.entities)
        if model.entity.class.respond_to?(:each_with_easy_level)
          model.entity.class.each_with_easy_level(entities) do |entity, level|
            yield entity, level
          end
        else
          entities.each do |entity|
            yield entity, nil
          end
        end
      end

      def self.entity_css_classes(entity, options = {})
        entity.css_classes if entity.respond_to?(:css_classes)
      end

      def entity_css_classes(entity, options = {})
        model.class.entity_css_classes(entity, options)
      end

      def has_context_menu?
        (options[:options] && options[:options].has_key?(:hascontextmenu)) ? options[:options][:hascontextmenu] : false
      end

      def modal_selector?
        (options[:options] && options[:options].has_key?(:modal_selector)) ? options[:options][:hascontextmenu] : false
      end

      # Returns a additional fast-icons buttons
      # - entity - instance of ...
      # - query - easy_query
      # - options - :no_link => true - no html links will be rendered
      #
      def additional_beginning_buttons(entity, options = {})
        return ''.html_safe if model.nil? || entity.nil?
        easy_query_additional_buttons_method = "#{model.class.name.underscore}_additional_beginning_buttons".to_sym

        additional_buttons = ''
        if h.respond_to?(easy_query_additional_buttons_method)
          additional_buttons = h.send(easy_query_additional_buttons_method, entity, options)
        end

        return additional_buttons.html_safe
      end

      def additional_ending_buttons(entity, options = {})
        return ''.html_safe if model.nil? || entity.nil?
        easy_query_additional_buttons_method = "#{model.class.name.underscore}_additional_ending_buttons".to_sym

        additional_buttons = ''
        if h.respond_to?(easy_query_additional_buttons_method)
          additional_buttons = h.send(easy_query_additional_buttons_method, entity, options)
        end

        return additional_buttons.html_safe
      end


      def column_header(column, options = {})
        if !options[:disable_sort] && column.sortable
          if page_module
            h.easy_page_module_sort_header_tag(page_module, model, column.name.to_s, { :class => column.css_classes, :caption => column.caption, :default_order => column.default_order })
          else
            h.sort_header_tag(column.name.to_s, { :class => column.css_classes, :caption => column.caption, :default_order => column.default_order })
          end
        else
          h.content_tag(:th, column.caption, { :class => column.css_classes })
        end
      end

      def operators_for_select(filter_type)
        EasyQueryFilter.operators_by_filter_type[filter_type].collect { |o| [l(EasyQueryFilter.operators[o]), o] }
      end

      def other_formats_links(options = {})
        if options[:no_container]
          yield RedmineExtensions::Export::EasyOtherFormatsBuilder.new(h)
        else
          h.concat('<div class="other-formats">'.html_safe)
          yield RedmineExtensions::Export::EasyOtherFormatsBuilder.new(h)
          h.concat('</div>'.html_safe)
        end
      end


      def available_columns_for_select
        h.options_for_select (model.available_columns - model.columns).reject(&:frozen?).collect { |column| [column.caption(true), column.name] }
      end

      def selected_columns_for_select
        h.options_for_select (model.columns & model.available_columns).reject(&:frozen?).collect { |column| [column.caption(true), column.name] }
      end

      #------- DATA FOR RESULTS -------

      # Returns count of entities on the list action
      # returns groups_count if query is grouped and entity_count otherwise
      def entity_count_for_list(options = {})
        if model.grouped?
          return model.groups_count(options)
        else
          return model.entity_count(options)
        end
      end

      def entities_for_html(options = {})
        options[:limit] ||= row_limit
        return model.entities_for_group(loading_group, options) if loading_group

        if model.grouped?
          return model.groups(options)
        else
          return model.entities(options)
        end
      end

      alias_method :prepare_html_result, :entities_for_html

      def entities_for_export(options = {})
        if model.grouped?
          return model.groups(options.merge(:include_entities => true))
        else
          return { nil => { :entities => model.entities(options), :sums => model.send(:summarize_entities, entities) } }
        end
      end

      alias_method :prepare_export_result, :entities_for_export

      def filters_active?
        model.filters.any?
      end

      #------ MIDDLE LAYER ------

      def path(params = {})
        model.path(params)
      end

      def entity_easy_query_path(options = {})
        model.entity_easy_query_path(options)
      end

      def outputs
        @outputs ||= EasyExtensions::EasyQueryHelpers::EasyOutputs.new(self)
      end

    end
  end
end
