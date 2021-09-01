module EasyExtensions
  module EasyQueryHelpers
    class EasyQueryOutput < RedmineExtensions::QueryOutput

      class_attribute :registered_per_query
      self.registered_per_query = {}

      def self.register_output_for_query(klass, query_class_names, **options)
        register_as ||= (options[:as] || klass.key).to_sym
        Array.wrap(query_class_names).each do |query_class_name|
          registered_per_query[query_class_name]              ||= {}
          registered_per_query[query_class_name][register_as] = klass
        end
      end

      # Defined on `RedmineExtensions::QueryOutput`
      #
      # def self.filter_registered_for(query)
      #   res = registered_outputs.select do |name, output|
      #     output.available_for?(query)
      #   end #super in feature...
      #   res.merge(registered_per_query[query.type] || {})
      # end

      def self.available_outputs_for(query)
        filter_registered_for(query).keys
      end

      def self.available_output_klasses_for(query)
        filter_registered_for(query).values
      end

      def self.output_klass_for(output, query = nil)
        filtered = registered_outputs
        filtered = filter_registered_for(query) if query
        filtered[output.to_sym]
      end

      def self.available_for?(query)
        query.class < EasyQuery
      end

      def self.displays_snapshot?
        false
      end

      def displays_snapshot?
        self.class.displays_snapshot?
      end

      def data_partial
        'easy_queries/easy_query_' + key
      end

      def order
        10
      end

      def configured?
        true
      end

      # should apply self settings to query defaults
      def apply_settings;
      end

      def restore_settings;
      end

      # try to load default query settings to setting of this output
      def configure_from_defaults;
      end

      def before_render
        apply_settings
      end

      def after_render
        restore_settings
      end

      def entity_json(entity)
        attributes             = {}
        attributes[:id]        = entity.id
        attributes[:edit_path] = h.polymorphic_path(entity, format: :json)
        query.inline_columns.each do |col|
          value                     = col.value(entity)
          attributes[col.name.to_s] = h.format_entity_attribute(query.entity, col, value, entity: entity, no_html: true).to_s
          if col.sumable? || (value && attributes[col.name.to_s] != value.to_s && !value.is_a?(ActiveRecord::Base))
            attributes["#{col.name}_raw"] = value
            attributes["#{col.name}_int"] = value.to_i if value.respond_to?(:to_i)
          end
          attributes["#{col.name}_id"] = value.to_param if value.is_a?(ActiveRecord::Base)
        end
        attributes
      end

      def before_api_render
        before_render
      end

      def after_api_render
        after_render
      end

      def render_callback(&block)
        before_render
        yield
      ensure
        after_render
      end

      def render_data
        if @query.is_snapshot? && !@query.snapshotable_columns?
          h.content_tag(:p, h.l(:label_easy_query_snapshot_no_snapshotable_columns), class: 'nodata')
        else
          render_callback { h.render partial: data_partial, locals: variables }
        end
      end

      def api_data_path(url_options = {})
        h.output_data_easy_queries_path(@query.to_params.merge(output: key, format: :json).merge(url_options))
      end

      def api_data
      end

      def render_api_data(api, options)
        before_api_render
        api.data api_data
      ensure
        after_api_render
      end

      def label
        h.l('label_easy_query_output.' + key, default: key.humanize)
      end

      def variables
        options.reverse_merge(easy_query: @query, output: self)
      end

      def header
        content = options["#{key}_header".to_sym]
        h.content_tag(:h3, content.html_safe) unless content.blank?
      end

      def render_edit_box(style = :check_box, options = {})
        box_id = "#{query.modul_uniq_id}output_#{key}"
        block_name = options[:block_name] || query.block_name

        options[:class]   = "#{options[:class]} output_switch"
        options[:enabled] = enabled? unless options.key?(:enabled)

        r = ''
        case style
        when :hidden_field
          r << h.hidden_field_tag(block_name.blank? ? 'outputs[]' : "#{block_name}[outputs][]", key, id: box_id, class: options[:class])
        when :check_box, :radio_button
          r << h.send("#{style}_tag", block_name.blank? ? 'outputs[]' : "#{block_name}[outputs][]", key, options[:enabled], id: box_id, class: options[:class])
          r << h.label_tag(box_id, h.l('label_my_page_issue_output.' + key), class: 'inline')
        else
          raise 'Style of edit box is not allowed'
        end
        r.html_safe
      end

      def render_edit(action = 'edit')
        h.content_tag(:fieldset, class: "easy-query-filters-field #{key}_settings", style: ('display: none;' unless enabled?)) do
          h.content_tag(:legend, label) + render_edit_form(action)
        end
      end

      def render_edit_form(action = 'edit')
        h.render(self.edit_form, options.reverse_merge(query: query, output: self, modul_uniq_id: query.modul_uniq_id, block_name: query.block_name, action: action, page_module: query.page_module))
      end

      def edit_form
        'easy_queries/form_' + key + '_settings'
      end

    end
  end
end
