module EasyPatch
  module DateFormatPatch

    def self.included(base)
      base.include(InstanceMethods)
      base.include(EasyExtensions::EasyQueryExtensions::DateTime)

      base.class_eval do

        attr_writer :period

        alias_method_chain :query_filter_options, :easy_extensions
        alias_method_chain :validate_single_value, :easy_extensions
        alias_method_chain :edit_tag, :easy_extensions
        alias_method_chain :order_statement, :easy_extensions
        alias_method_chain :group_statement, :easy_extensions

        self.type_for_inline_edit = 'dateui'

        def date?(_custom_field)
          true
        end

      end
    end

    module InstanceMethods

      def value_for_inline_edit(view, custom_field_value, html = false)
        view.format_date(custom_field_value.value)
      end

      def query_filter_options_with_easy_extensions(custom_field, query)
        { :type => :date_period }
      end

      def edit_tag_with_easy_extensions(view, tag_id, tag_name, custom_value, options = {})
        custom_value.value = User.current.today if custom_value.value.blank? && custom_value.custom_field.settings['default_is_today'] == '1'
        edit_tag_without_easy_extensions(view, tag_id, tag_name, custom_value, options)
      end

      def validate_single_value_with_easy_extensions(custom_field, value, customized = nil)
        if value.is_a?(Date)
          return []
        else
          validate_single_value_without_easy_extensions(custom_field, value, customized)
        end
      end

      def order_statement_with_easy_extensions(custom_field)
        statement = timestamp_cast(order_statement_without_easy_extensions(custom_field))
        if @period
          statement = date_condition(statement, @period)
        end
        Arel.sql(custom_field.class.send(:sanitize_sql_array, statement))
      end

      def group_statement_with_easy_extensions(custom_field)
        order_statement(custom_field)
      end

    end

  end
end
