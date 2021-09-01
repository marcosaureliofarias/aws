module EasyButtons
  class QueryBase

    attr_reader :key, :options, :definition, :query

    def self.reject_collection_filters(query, filters)
      filters = filters.dup

      filters.keep_if do |key, options|
        if key =~ /^(.+)_cf_(\d+)/
          assoc = $1
        else
          assoc = key
        end

        assoc_klass = query.entity.reflect_on_association(assoc)
        if assoc_klass && assoc_klass.collection?
          false
        else
          true
        end
      end

      filters
    end

    def self.reject_non_write_filters(query, filters)
      filters = filters.dup

      filters.keep_if do |key, options|
        if key =~ /^(.+)_cf_(\d+)/ || key =~ /^(.+)\.(.+)/
          false
        else
          true
        end
      end

      filters
    end

    def self.reader_filters(easy_button)
      query = easy_button.conditions_query
      filters = EasyButtons::QueryBase.reject_collection_filters(query, query.reader_filters)
    end

    def self.writer_filters(easy_button)
      query = easy_button.actions_query
      filters = query.writer_filters

      filters = EasyButtons::QueryBase.reject_collection_filters(query, filters)
      filters = EasyButtons::QueryBase.reject_non_write_filters(query, filters)

      if query.is_a?(EasyIssueQuery)
        _, assignee_definition = filters.find {|(name, _)| name == 'assigned_to_id' }

        if assignee_definition
          new_options = assigned_to_id_additional_select_options.map{|o| o.join('|') }.join(';')

          assignee_definition[:source_options] ||= {}
          assignee_definition[:source_options][:additional_select_options] = new_options
        end
      end

      filters
    end

    def self.assigned_to_id_additional_select_options
      {
        I18n.t(:label_unassignee_assigned_to) => 'none',
        I18n.t(:label_author_assigned_to) => 'author',
        I18n.t(:label_last_user_assigned_to) => 'last_assigned',
      }
    end

    def self.ignore_author_subordinates_select_options
    end

    def initialize(key, options, definition, query)
      @key = key
      @options = options
      @definition = definition
      @query = query
    end

    def self.parse(query, definitions)
      result = []
      definitions = Hash[definitions] if definitions.is_a?(Array)

      query.filters.each do |key, options|
        definition = definitions[key]

        # Filter does not have 'attr_reader' or 'attr_writer' option
        next if definition.nil?

        result << self.new(key, options, definition, query).parse
      end

      result.compact!
      result
    end

    def parse
      case type
      when :list
        create_list
      when :list_status
        create_list_status
      when :list_optional
        create_list_optional
      when :list_autocomplete
        create_list_autocomplete
      when :float
        create_float
      when :integer
        create_integer
      when :string
        create_string
      when :text
        create_string
      when :boolean
        create_boolean
      else
        raise "EasyActionButton: Type #{type} is not supported."
      end
    end

    def create_list; end
    def create_list_status; end
    def create_list_optional; end
    def create_float; end
    def create_integer; end
    def create_string; end
    def create_boolean; end
    def create_list_autocomplete; end

    def possible_values
      definition[:values]
    end

    def type
      definition[:type]
    end

    def values
      options[:values]
    end

    def values_as_int
      @values_as_int ||= values.map(&:to_i)
    end

    def values_as_float
      @values_as_float ||= values.map(&:to_f)
    end

    def values_as_string
      return @values_as_string if @values_as_string

      @values_as_string = options[:values].to_s

      if query.columns_with_me.include?(key) || (definition[:field] && definition[:field].format.target_class && definition[:field].format.target_class <= User)
        @values_as_string.gsub!('"me"', 'User.current.id.to_s')
      end

      @values_as_string
    end

    def operator
      options[:operator]
    end

    def key_without_id
      @key_without_id ||= @key.gsub(/\_id$/, '')
    end

    def cf
      @cf ||= key.match(/((\w*)_)?cf_(\d+)/)
    end

    def cf?
      !!cf
    end

    def cf_id
      cf && cf[3].to_i
    end

    def cf_entity
      cf && cf[2]
    end

    def get_value
      if cf?
        if cf_entity
          "entity.#{cf_entity} && entity.#{cf_entity}.custom_field_value(#{cf_id})"
        else
          "entity.custom_field_value(#{cf_id})"
        end
      else
        "entity.#{key}"
      end
    end

    def checking_id?
      @checking_id ||= possible_values.first.is_a?(Array) ? true : false
    end

  end
end
