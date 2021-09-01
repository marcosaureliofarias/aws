require 'easy_extensions/spec_helper'

describe EasyContactsToolbarController, logged: :admin do
  render_views

  let!(:easy_contact1) { FactoryBot.create(:easy_contact, firstname: 'Soft Energy') }
  let!(:easy_contact2) { FactoryBot.create(:easy_contact) }

  it 'assignable_principals crm' do
    get :search, params: { easy_query_q: 'energy', format: 'html' }
    expect(assigns[:easy_contacts]).to match_array([easy_contact1])
  end
end