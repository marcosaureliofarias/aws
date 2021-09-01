module EasyContactPatch
  module EasyEntityActivityDecoratorPatch

    def self.included(base)

      base.class_eval do

        def easy_contact_attendees
          selected = easy_entity_activity_attendees.where(entity_type: 'EasyContact').map { |eea| { id: eea.entity_id, value: eea.to_s } }
          if selected.empty?
            if entity_type == 'EasyCrmCase'
              if easy_crm_case.main_easy_contact_id
                selected.concat([{ id: easy_crm_case.main_easy_contact_id, value: easy_crm_case.main_easy_contact.to_s }])
              else
                selected.concat(easy_crm_case.easy_contacts.includes(:easy_contact_type).where(easy_contact_type: {internal_name: 'personal'}).map{|x| {id: x.id, value: x.to_s}})
              end
            elsif entity_type == 'EasyContact'
              selected.concat([{ id: easy_contact.id, value: easy_contact.to_s }])
            end
          end
          selected
        end
      end
    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'EasyEntityActivityDecorator', 'EasyContactPatch::EasyEntityActivityDecoratorPatch'
