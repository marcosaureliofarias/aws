require 'easy_extensions/spec_helper'

describe EasyAutoCompletesController, logged: :admin do
  render_views

  let(:easy_crm_case) { FactoryBot.create(:easy_crm_case) }

  it 'assignable_principals crm' do
    get :index, params: { autocomplete_action: 'assignable_principals_easy_crm_case', format: 'json' }
    expect(response).to be_successful
  end

  it 'assignable_principals crm id' do
    get :index, params: { autocomplete_action: 'assignable_principals_easy_crm_case', format: 'json', easy_crm_case_id: easy_crm_case.id }
    expect(response).to be_successful
  end
end