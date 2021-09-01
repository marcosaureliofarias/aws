require 'easy_extensions/spec_helper'

describe Issue, logged: :admin do
  let(:easy_contact_type) { FactoryGirl.create(:easy_contact_type) }
  let!(:email_cf) { FactoryGirl.create(:easy_contact_custom_field, field_format: 'email', contact_types: [easy_contact_type]) }
  let!(:email_cfd) { FactoryGirl.create(:easy_contact_custom_field, field_format: 'email', contact_types: [easy_contact_type]) }

  let!(:contact_with_email_cf) do
    contacts = []
    contacts << FactoryGirl.create(:easy_contact, type_id: easy_contact_type.id, custom_field_values: 
      {email_cf.id.to_s => 'tat@ad.com'}
    )
    contacts << FactoryGirl.create(:easy_contact, type_id: easy_contact_type.id, custom_field_values: 
      {email_cf.id.to_s => 'x@ad.com', email_cfd.id.to_s => 'mam@a.com'}
    )
    contacts
  end
  let(:issue) { FactoryGirl.build(:issue, easy_email_to: 'tat@ad.com', easy_email_cc: 'ete@ad.com, mam@a.com, main@admin.com') }

  context 'callback#assign_contacts' do
    it 'create contacts' do
      issue.save
      issue.reload
      expect(issue.easy_contacts).to match_array(contact_with_email_cf)
    end
  end
end
