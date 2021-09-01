module EasyExtensions
  module Tracking

    CUSTOM_PARAMS = %i(utm_source utm_medium utm_campaign utm_content utm_term)

    mattr_accessor :enabled
    self.enabled = false

    class << self

      def enabled?
        !!self.enabled
      end

      def to_params(params)
        return {} unless enabled?

        params
      end

    end

  end
end
