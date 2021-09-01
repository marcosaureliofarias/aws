module EasyButtons
  ##
  # EasyActionButtonMethod
  #
  # Line should end by ';' (just in case)
  #
  class QueryAction < QueryBase

    RESULT_VARIABLE_NAME = 'params'

    OPERATORS = {
      list: ['='],
      list_optional: ['='],
      list_status: ['='],
      string: ['='],
      integer: ['=', '+=', '-='],
      float: ['=', '+=', '-='],
      boolean: ['='],
      easy_lookup: ['='],
      list_autocomplete: ['=']
    }

    def self.parse(query, entity_options)
      # Variable initialize
      result = %{
        #{RESULT_VARIABLE_NAME} = {};
        #{RESULT_VARIABLE_NAME}['custom_field_values'] = {};
      }

      # Set variables
      result << super(query, query.writer_filters).join(';')

      result
    end

    # Variable `__value__` must be created before using this method
    def set_value
      if cf?
        "#{RESULT_VARIABLE_NAME}['custom_field_values'][#{cf_id}] = __value__.to_s"
      else
        "#{RESULT_VARIABLE_NAME}['#{key}'] = __value__.to_s"
      end
    end

    def create_numeric(conversion_mark)
      value = values.first.__send__(conversion_mark)

      result = %{
        origin_value = #{get_value}.#{conversion_mark};
        __value__ = #{value};
      }

      result <<
        case operator
        when '+='
          "__value__ = origin_value + __value__;"
        when '-='
          "__value__ = origin_value - __value__;"
        else
          ''
        end

      result << "#{set_value};"
      result
    end

    def safe_value
      return @safe_value if @safe_value

      value = values.first

      # TO CONSIDER: rename {columns_with_me} to {columns_with_???}
      if query.columns_with_me.include?(key)

        case value
        when 'me'
          @safe_value = 'User.current.id.to_s'

        when 'none'
          @safe_value = 'nil'

        when 'author'
          @safe_value = "(entity.respond_to?(:author_id) ? entity.author_id : nil)"

        when 'last_assigned'
          @safe_value = "(entity.respond_to?(:last_user_assigned_to) ? entity.last_user_assigned_to.try(:id) : nil)"
        end
      end

      @safe_value ||= "'" + value.to_s.gsub('\'', '\\\\\'') + "'"

      @safe_value
    end

    def create_common
      %{
        __value__ = #{safe_value};
        #{set_value};
      }
    end

    def create_float
      create_numeric(:to_f)
    end

    def create_integer
      create_numeric(:to_i)
    end

    alias_method :create_list, :create_common
    alias_method :create_list_status, :create_common
    alias_method :create_list_optional, :create_common
    alias_method :create_list_autocomplete, :create_common
    alias_method :create_string, :create_common
    alias_method :create_boolean, :create_common

  end
end
