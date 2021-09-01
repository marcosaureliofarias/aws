require 'easy_extensions/spec_helper'

describe EasyContactTypesController, logged: :admin do

  let(:contact) { FactoryBot.create(:easy_contact, easy_contact_type: easy_contact_type) }
  let(:easy_contact_type) { FactoryBot.create(:easy_contact_type, is_default: false) }
  let(:easy_contact_type_to) { FactoryBot.create(:easy_contact_type, is_default: false) }
  let(:easy_contact_custom_field) { FactoryBot.create(:easy_contact_custom_field, contact_type_ids: [easy_contact_type.id, easy_contact_type_to.id]) }
  let(:easy_contact_custom_field_to) { FactoryBot.create(:easy_contact_custom_field, contact_type_ids: [easy_contact_type.id, easy_contact_type_to.id]) }

  it '#move_easy_contacts' do
    easy_contact_custom_field
    contact.reload
    contact.custom_field_values = {easy_contact_custom_field.id.to_s => 'test'}
    contact.save
    expect(contact.reload.custom_values.count).to eq(1)
    post :move_easy_contacts, params: {id: easy_contact_type.id, easy_contact_type_to_id: easy_contact_type_to.id,
      custom_fields_map: {easy_contact_custom_field.id => easy_contact_custom_field_to.id}}
    expect(EasyContactType.find_by(id: easy_contact_type.id)).to eq(nil)
    contact.reload
    expect(contact.easy_contact_type).to eq(easy_contact_type_to)
    expect(contact.custom_values.count).to eq(1)
    expect(contact.custom_value_for(easy_contact_custom_field_to.id).value).to eq('test')
  end

  it 'update custom fields' do
    easy_contact_custom_field
    expect(easy_contact_type.reload.custom_field_ids).to eq([easy_contact_custom_field.id])
    put :update, params: {id: easy_contact_type.id, easy_contact_type: {custom_field_ids: ['']}}
    expect(easy_contact_type.reload.custom_field_ids).to eq([])
  end
end
