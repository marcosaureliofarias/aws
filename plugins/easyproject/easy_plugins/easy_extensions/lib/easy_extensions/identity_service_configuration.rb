module EasyExtensions
  class IdentityServiceConfiguration
    include Rails.application.routes.url_helpers

    attr_accessor :condition
    attr_accessor :title, :description
    attr_writer :settings_path, :show_path

    def initialize
    end

    def active?
      if condition.is_a?(Proc)
        condition.call
      else
        !!condition
      end
    end

    def title
      if @title.is_a?(Proc)
        @title.call
      else
        @title
      end
    end

    def description
      if @description.is_a?(Proc)
        @description.call
      else
        @description
      end
    end

    def settings_path(options = {})
      path(@settings_path, options)
    end

    def show_path(options = {})
      path(@show_path, options)
    end

    private

    def path(value, options = {})
      case value
      when Symbol
        send(value, options)
      when String
        if options.blank?
          value
        else
          value + (value.include?('?') ? '&' : '?') + options.to_query
        end
      when Array
        value = value.dup
        new_args, new_path = value, value.shift
        send(new_path, *new_args.push(options))
      end
    end

  end
end
