module EasyCrm
  module EasyContactPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        has_many :easy_crm_cases, lambda { where(easy_contact_entity_assignments: { entity_type: 'EasyCrmCase' }) }, through: :easy_contact_entity_assignments, as: :entity
        has_many :related_easy_crm_cases, inverse_of: :main_easy_contact, class_name: 'EasyCrmCase', foreign_key: 'main_easy_contact_id'
        has_many :main_easy_crm_cases, class_name: 'EasyCrmCase', foreign_key: 'main_easy_contact_id', dependent: :nullify # remove? copy of above

        alias_method_chain :sales_activities, :easy_crm

      end
    end

    module InstanceMethods

      def sales_activities_with_easy_crm
        eea = EasyEntityActivity.arel_table
        @sales_activities ||= EasyEntityActivity.
                             where(eea.
                                      grouping(
                                      eea[:entity_type].eq('EasyContact').
                                        and(eea[:entity_id].eq(self.id))
                                      ).or(
                                      eea.grouping(
                                      eea[:entity_type].eq('EasyCrmCase').
                                        and(eea[:entity_id].in(self.easy_crm_case_ids))
                                      )).or(
                                      eea.grouping(
                                      eea[:entity_type].eq('EasyCrmCase').
                                        and(eea[:entity_id].in(self.main_easy_crm_case_ids))
                                      ))
                                   ).sorted
      end

    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_model_patch('EasyContact', 'EasyCrm::EasyContactPatch', :if => Proc.new{Redmine::Plugin.installed?(:easy_contacts)})
