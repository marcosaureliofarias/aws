module ActionController
  module MobileFu

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      def has_mobile_fu(options = {})
        include ActionController::MobileFu::InstanceMethods

        helper_method :is_mobile_device?
        helper_method :in_mobile_view?

      end
    end

    module InstanceMethods

      def in_mobile_view?
        return false if api_request?
        is_mobile_device?
      end

      def is_mobile_device?
        !!browser.device.mobile?
      end

    end

  end

end

ActionController::Base.include(ActionController::MobileFu)
