require_relative '../spec_helper'

describe EasyCrmCaseItemsController, :logged => :admin do

  let!(:easy_crm_case_item) { FactoryGirl.create(:easy_crm_case_item) }

  render_views

  it 'index' do
    get :index
    assert_response :success
  end

  it 'index json' do
    get :index, :params => {:format => 'json'}
    assert_response :success
  end

  it 'destroy' do
    expect{delete :destroy, :params => {:id => easy_crm_case_item.id.to_s}}.to change(EasyCrmCaseItem, :count).by(-1)
  end

  it 'bulk destroy' do
    expect{delete :bulk_destroy, :params => {:ids => [easy_crm_case_item.id.to_s]}}.to change(EasyCrmCaseItem, :count).by(-1)
  end

  it 'update easy_crm_case_items' do
    put :update_easy_crm_case_items, params: { id: easy_crm_case_item.easy_crm_case.id, format: 'js' }, xhr: true
    expect(response).to be_successful
  end
end
