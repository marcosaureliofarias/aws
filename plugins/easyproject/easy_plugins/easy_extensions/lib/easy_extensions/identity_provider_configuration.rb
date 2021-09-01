module EasyExtensions
  class IdentityProviderConfiguration
    include Rails.application.routes.url_helpers

    attr_accessor :support_sso, :login_button, :condition, :checked
    attr_accessor :title, :description
    attr_writer :settings_path, :login_path, :show_path

    def initialize
      @login_path = nil
    end

    def support_sso?
      !!support_sso
    end

    def login_button?
      if login_button.is_a?(Proc)
        login_button.call
      else
        !!login_button
      end
    end

    def active?
      if condition.is_a?(Proc)
        condition.call
      else
        !!condition
      end
    end

    def checked?
      if checked.is_a?(Proc)
        checked.call
      else
        !!checked
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

    def login_path(options = {})
      path(@login_path, options)
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
