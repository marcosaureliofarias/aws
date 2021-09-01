Rys::Patcher.add('CustomField') do
  apply_if_plugins :easy_extensions

  included do
    def easy_query_name
      settings['associated_query']
    end

    def easy_computed_from_query_format=(format)
      self.settings = self.settings.merge('easy_computed_from_query_format' => format)
    end

    def easy_original_custom_field_format
      if field_format == 'easy_computed_token'
        self.settings['easy_computed_token_format']
      elsif field_format == 'easy_computed_from_query'
        self.settings['easy_computed_from_query_format']
      else
        field_format
      end
    end

    def join_for_order_statement_by_field_format_easy_computed_token
      m = "join_for_order_statement_by_field_format_#{easy_original_custom_field_format}".to_sym
      if respond_to?(m)
        send(m)
      else
        nil
      end
    end

    def create_easy_query
      return if settings['associated_query'].blank?

      easy_query_class = settings['associated_query'].safe_constantize
      return unless easy_query_class
      easy_query_filters = settings['easy_query_filters']
      query = easy_query_class.new

      if easy_query_filters
        query.filters = {}
        query.add_filters(easy_query_filters[:fields], easy_query_filters[:operators], easy_query_filters[:values]) if easy_query_filters[:fields]
      end

      query
    end

    def create_clear_easy_query
      return if easy_query_name.blank?

      query = easy_query_name.constantize.new
      query.available_filters
      query.available_columns
      query.filters = {}
      query.column_names = {}
      query
    end

    def apply_easy_query_filters(query)
      easy_query_filters = settings['easy_query_filters']

      if easy_query_filters
        query.filters = {}

        if easy_query_filters[:fields]
          query.add_filters(easy_query_filters[:fields], easy_query_filters[:operators], easy_query_filters[:values])
        end
      end

      query
    end

    def easy_with_computed_faked_format(&block)
      original_field_format = field_format.dup
      self.send(:write_attribute, :field_format, easy_original_custom_field_format)
      @format = nil
      result = instance_eval(&block)
      self.send(:write_attribute, :field_format, original_field_format)
      @format = nil
      result
    end

    def easy_query_column_currency_code
      settings['easy_query_column_currency'].presence || EasyCurrency.default_code
    end
  end

  instance_methods(feature: 'easy_computed_field_from_query') do
    def set_searchable
      self.is_required = false if ['easy_computed_from_query'].include?(field_format)
      super
    end

    def available_form_fields
      result = super
      result.delete(:is_required) if ['easy_computed_from_query'].include?(field_format)
      result
    end

    def order_statement
      easy_with_computed_faked_format do
        super
      end
    end

    def group_statement
      easy_with_computed_faked_format do
        super
      end
    end

    def summable?
      super || ['int', 'float', 'amount'].include?(easy_original_custom_field_format)
    end

    def summable_sql
      easy_with_computed_faked_format do
        super
      end
    end
  end

  class_methods do
    def visible
      if Rys::Feature.active?('easy_computed_field_from_query')
        super
      else
        super.where.not(field_format: 'easy_computed_from_query')
      end
    end
  end
end
