require 'easy_extensions/spec_helper'
describe EasyContactsController do
  include_context "a requests actions", :easy_contact, [:view_easy_contacts] do
    before { FactoryBot.create(:easy_user_type, is_default: true) }

    def assign_permissions(permissions)
      role = Role.non_member
      allow(role).to receive(:easy_contacts_visibility).and_return "all"
      role.add_permission! *permissions
      User.current.easy_user_type&.update easy_contact_type_ids: EasyContactType.ids
      user.easy_user_type.update easy_contact_type_ids: EasyContactType.ids
    end
  end
end