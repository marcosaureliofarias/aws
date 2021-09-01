module EasyChecklistPlugin
  module EasyCrmCasePatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        include EasyPatch::Acts::ActsAsEasyChecklist
        acts_as_easy_checklist

      end
    end

    module InstanceMethods

    end

    module ClassMethods

    end

  end

end
RedmineExtensions::PatchManager.register_model_patch 'EasyCrmCase', 'EasyChecklistPlugin::EasyCrmCasePatch' if Redmine::Plugin.installed?(:easy_crm)
