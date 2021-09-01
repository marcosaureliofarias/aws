module EasyCrm
  module ProjectPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        has_many :easy_crm_cases, :dependent => :destroy
        has_many :easy_entity_assigned, :class_name => 'EasyEntityAssignment', :as => :entity_to, :dependent => :delete_all

      end
    end

    module InstanceMethods

    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'Project', 'EasyCrm::ProjectPatch'
