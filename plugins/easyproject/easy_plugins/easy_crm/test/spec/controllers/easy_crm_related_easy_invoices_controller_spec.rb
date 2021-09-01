require_relative '../spec_helper'

describe EasyCrmRelatedEasyInvoicesController, :logged => :admin do
  let(:project) {FactoryGirl.create(:project, :add_modules => ['easy_crm', 'easy_invoicing'])}
  let(:easy_crm_case) {FactoryGirl.create(:easy_crm_case, :project => project)}
  let!(:easy_invoice) {FactoryGirl.create(:easy_invoice, :project => project)}

  render_views

  it 'should get index in html' do
    get :index, :params => {:id => easy_crm_case.id, :format => 'html'}
    assert_response :success
  end

  it 'should get index in json' do
    get :index, :params => {:id => easy_crm_case.id, :format => 'json'}
    assert_response :success
    expect(json).to have_key(:easy_invoices)
  end

  it 'should assign easy invoice to crm case' do
    post :create, :params => {:id => easy_crm_case, :easy_invoice_id => easy_invoice.id}
    assert_response :redirect
    expect(easy_crm_case.easy_invoice_ids).to include(easy_invoice.id)
  end

end if Redmine::Plugin.installed?(:easy_invoicing)
