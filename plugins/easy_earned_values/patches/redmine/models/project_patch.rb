module EasyEarnedValues
  module ProjectPatch

    def self.included(base)
      base.class_eval do
        has_many :easy_earned_values, dependent: :destroy
      end
    end

  end
end

RedmineExtensions::PatchManager.register_model_patch 'Project', 'EasyEarnedValues::ProjectPatch'
