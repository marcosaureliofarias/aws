require 'base64'

module EasyButtons
  class QueryCondition < QueryBase

    def self.parse(query)
      super(query, query.reader_filters)
    end

    # 'o', '=', '!', 'c', '*'
    def create_list_status
      case operator
      when 'o', 'c'
        true_false = (operator == 'c')
        "entity.#{key_without_id} && entity.#{key_without_id}.is_closed == #{true_false}"

      when '=', '!'
        true_false = (operator == '=')
        "#{values_as_int}.include?(#{get_value}) == #{true_false}"

      when '*'
        "entity.#{key}.nil? == false"
      end
    end

    # Nil is converted to 0.0
    #
    # '=', '>=', '<=', '><', '!*', '*'
    def create_float
      case operator
      when '='
        value = values.first.to_f
        "#{get_value}.to_f == #{value}"

      when '>=', '<='
        value = values.first.to_f
        "#{get_value} && #{get_value}.to_f #{operator} #{value}"

      when '><'
        value1 = values[0].to_f
        value2 = values[1].to_f
        "#{get_value} && #{get_value}.to_f >= #{value1} && #{get_value}.to_f <= #{value2}"

      when '*', '!*'
        true_false = (operator == '!*')
        "#{get_value}.nil? == #{true_false}"
      end
    end

    # '=', '>=', '<=', '><', '!*', '*'
    def create_integer
      case operator
      when '='
        value = values.first.to_i
        "#{get_value}.to_i == #{value}"

      when '>=', '<='
        value = values.first.to_i
        "#{get_value} && #{get_value}.to_i #{operator} #{value}"

      when '><'
        value1 = values[0].to_i
        value2 = values[1].to_i
        "#{get_value} && #{get_value}.to_i >= #{value1} && #{get_value}.to_i <= #{value2}"

      when '*', '!*'
        true_false = (operator == '!*')
        "#{get_value}.nil? == #{true_false}"
      end
    end

    # '=', '!
    def create_list
      true_false = (operator == '=')
      "#{values_as_string}.include?(#{get_value}.to_s) == #{true_false}"
    end

    # '=', '!', '!*', '*'
    def create_list_autocomplete
      create_list_optional
    end

    # Always is used a String
    #
    # '=', '!', '!*', '*'
    def create_list_optional
      case operator
      when '=', '!'
        true_false = (operator == '=')
        "#{values_as_string}.include?(#{get_value}.to_s) == #{true_false}"

      when '!*', '*'
        true_false = (operator == '!*')
        "#{get_value}.blank? == #{true_false}"
      end
    end

    # =   is
    # !   is not
    # ~   contains
    # !~  doesn't contain
    # ^~  starts with
    # !*  none
    # *   any
    def create_string
      case operator
      when '=', '!'
        op = (operator == '=' ? '==' : '!=')
        "#{get_value} #{op} \"#{values.first.to_s}\""

      when '~', '!~'
        op = (operator == '~' ? '=~' : '!~')
        value = Base64.strict_encode64(values.first.to_s)
        value = "Regexp.new(Regexp.escape(Base64.strict_decode64('#{value}')))"
        "#{get_value} && #{get_value} #{op} #{value}"

      when '^~'
        "#{get_value} && #{get_value}.start_with?(\"#{values.first.to_s}\")"

      when '*', '!*'
        true_false = (operator == '!*')
        "#{get_value}.blank? == #{true_false}"
      end
    end

    # Operator is always =, values are 0 or 1
    def create_boolean
      true_false = (values.first == '1')
      "#{get_value} == #{true_false}"
    end

  end
end
