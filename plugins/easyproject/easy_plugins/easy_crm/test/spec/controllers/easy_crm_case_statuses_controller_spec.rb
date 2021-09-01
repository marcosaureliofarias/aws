require_relative '../spec_helper'

describe EasyCrmCaseStatusesController, :logged => :admin do

  let(:project) { FactoryGirl.create(:project, :add_modules => ['easy_crm']) }
  let(:easy_crm_case_status) { FactoryGirl.create(:easy_crm_case_status) }

  render_views

  it 'should check new' do
    get :new
    assert_response :success
  end

  it 'should check edit' do
    get :edit, :params => {:id => easy_crm_case_status.id, :project_id => project.id}
    assert_response :success
  end

  it 'index json' do
    get :index, :params => {:format => 'json'}
    assert_response :success
  end
end
