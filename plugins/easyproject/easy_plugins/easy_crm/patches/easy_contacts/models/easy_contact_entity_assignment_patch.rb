module EasyCrm
  module EasyContactEntityAssignmentPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        belongs_to :easy_crm_case, :foreign_key => 'entity_id', :foreign_type => 'EasyCrmCase'

      end
    end

    module InstanceMethods

    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_model_patch('EasyContactEntityAssignment', 'EasyCrm::EasyContactEntityAssignmentPatch', :if => Proc.new{Redmine::Plugin.installed?(:easy_contacts)})
