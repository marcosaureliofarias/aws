module ActionMailer
  module MailHelper

    # `*_path` methods are removed from rails 5 but
    # since we have common helpers for mailers and
    # controllers its quite difficult
    #
    # https://github.com/rails/rails/pull/15840
    #
    def method_missing(name, *args, &block)
      if name.to_s.end_with?('_path')
        url_name = name.to_s.sub('_path', '_url')

        if respond_to?(url_name)
          return send(url_name, *args, &block)
        end
      end

      super
    end

  end
end
