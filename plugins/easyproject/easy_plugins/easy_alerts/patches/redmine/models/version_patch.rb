module EasyAlerts
  module VersionPatch

    def self.included(base)
      base.class_eval do

        scope :alerts_active_projects, -> { joins(:project).merge(Project.active) }

      end
    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'Version', 'EasyAlerts::VersionPatch'
