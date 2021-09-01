module EasyAlerts
  module UserPatch

    def self.included(base)
      base.class_eval do
        base.include(InstanceMethods)

        alias_method_chain :remove_references_before_destroy, :easy_alerts
      end
    end

    module InstanceMethods
      def remove_references_before_destroy_with_easy_alerts
        remove_references_before_destroy_without_easy_alerts
        substitute = User.anonymous
        AlertReport.where(['user_id = ?', self.id]).destroy_all
        Alert.where(['author_id = ?', self.id]).update_all(['author_id = ?', substitute.id])
      end
    end
  end
end
EasyExtensions::PatchManager.register_model_patch 'User', 'EasyAlerts::UserPatch'
