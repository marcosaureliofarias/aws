require 'easy_extensions/spec_helper'

describe CustomFieldEnumerationsController, logged: :admin do

  let(:custom_field) { FactoryGirl.create(:user_custom_field, field_format: 'enumeration') }

  it 'Create custom field enumeration' do
    expect {
      post :create, params: { custom_field_enumeration: { name: 'custom_field_enumeration.name' },
                              custom_field_id:          custom_field } }.to change(CustomFieldEnumeration, :count).by(1)
  end

  it 'Create custom field enumeration with wrong params' do
    expect {
      post :create, params: { custom_field_enumeration: { name: '' },
                              custom_field_id:          custom_field.id } }.to change(CustomFieldEnumeration, :count).by(0)
    expect(response).to redirect_to(custom_field_enumerations_path(custom_field))
    expect(flash[:alert]).to be_present
  end

  it 'test js response if args wrong' do
    expect {
      post :create, params: { custom_field_enumeration: { name: '' },
                              custom_field_id:          custom_field.id } }.to change(CustomFieldEnumeration, :count).by(0)
    expect(response.status).to eq(302)
  end

end
