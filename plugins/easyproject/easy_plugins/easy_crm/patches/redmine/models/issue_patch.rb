module EasyCrm
  module IssuePatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        has_and_belongs_to_many :easy_crm_cases

      end
    end

    module InstanceMethods

    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'Issue', 'EasyCrm::IssuePatch'
