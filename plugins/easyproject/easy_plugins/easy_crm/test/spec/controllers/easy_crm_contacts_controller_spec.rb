require_relative '../spec_helper'

describe EasyCrmContactsController, :logged => :admin do

  let(:project) { FactoryGirl.create(:project, :add_modules => ['easy_crm', 'easy_contacts']) }
  let(:easy_crm_case) { FactoryGirl.create(:easy_crm_case, :with_contacts, :project => project)}

  render_views

  it 'index' do
    easy_crm_case
    get :index, :params => {:id => project.id}
    assert_response :success
    expect(assigns(:entities).count).to eq(easy_crm_case.easy_contacts.count)
  end
end
