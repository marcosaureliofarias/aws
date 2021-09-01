module EasyPatch
  module ActsAsVersionedPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :save_version_on_create, :easy_extensions
        alias_method_chain :save_version, :easy_extensions

      end
    end

    module InstanceMethods

      def save_version_on_create_with_easy_extensions
        unless save_version?
          msg = "save_version_on_create - #{self.class.name + ': ' + self.as_json.symbolize_keys.to_s}"
          msg.concat("\ncondition met: #{version_condition_met?}")
          msg.concat("\ntrack attrs: #{!!self.class.track_altered_attributes}")
          msg.concat("\naltered attrs: #{altered_attributes}")
          Rails.logger.info msg
          return
        end
        save_version_on_create_without_easy_extensions
      end

      def save_version_with_easy_extensions
        if save_version?
          save_version_on_create
        else
          msg = "save_version - #{self.class.name + ': ' + self.as_json.symbolize_keys.to_s}"
          msg.concat("\ncondition met: #{version_condition_met?}")
          msg.concat("\ntrack attrs: #{!!self.class.track_altered_attributes}")
          msg.concat("\naltered attrs: #{altered_attributes}")
          Rails.logger.info msg
        end
      end

    end

  end
end
#EasyExtensions::PatchManager.register_redmine_plugin_patch 'ActiveRecord::Acts::Versioned::ActMethods', 'EasyPatch::ActsAsVersionedPatch'
