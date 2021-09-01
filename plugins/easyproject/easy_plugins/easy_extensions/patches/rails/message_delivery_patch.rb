module EasyPatch
  module MessageDeliveryPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :deliver_later, :easy_extensions

      end
    end

    module InstanceMethods

      def deliver_later_with_easy_extensions(options = {})
        return if !ActionMailer::Base.perform_deliveries

        deliver_later_without_easy_extensions(options)
      end

    end

  end
end
EasyExtensions::PatchManager.register_rails_patch 'ActionMailer::MessageDelivery', 'EasyPatch::MessageDeliveryPatch'
