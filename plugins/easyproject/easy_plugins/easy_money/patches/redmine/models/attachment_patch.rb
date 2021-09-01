module EasyMoney
  module AttachmentPatch

    def self.included(base)
      base.extend(ClassMethods)
      # base.send(:include, InstanceMethods)
      base.class_eval do

        class << self
          alias_method_chain :allowed_containers_for_query, :easy_money
        end
      end
    end

    module ClassMethods

      def allowed_containers_for_query_with_easy_money
        containers = allowed_containers_for_query_without_easy_money
        containers.concat(['EasyMoneyTravelExpense', 'EasyMoneyTravelCost', 'EasyMoneyExpectedExpense', 'EasyMoneyOtherExpense', 'EasyMoneyExpectedRevenue', 'EasyMoneyOtherRevenue'])
        containers
      end
    end
  end
end
EasyExtensions::PatchManager.register_model_patch 'Attachment', 'EasyMoney::AttachmentPatch'