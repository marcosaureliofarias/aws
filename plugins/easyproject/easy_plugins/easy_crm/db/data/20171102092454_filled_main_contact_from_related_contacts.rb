class FilledMainContactFromRelatedContacts < ActiveRecord::Migration[4.2]
  def up
    unless Redmine::Plugin.installed?(:modification_easysoftware)

      EasyCrmCase.preload({ easy_contacts: :easy_contact_type }).where(main_easy_contact_id: nil).find_each(batch_size: 200) do |crm|

        if crm.easy_contacts.size == 1
          crm.update_column(:main_easy_contact_id, crm.easy_contacts.first.id)
        elsif crm.easy_contacts.size > 1
          contact = crm.easy_contacts.detect { |c| c.type.is_default? } || crm.easy_contacts.first
          if contact
            crm.update_column(:main_easy_contact_id, contact.id)
          end
        end
      end

    end
  end
end
