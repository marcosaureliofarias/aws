require_relative '../spec_helper'

describe EasyCrmCasesController, :logged => :admin do
  let(:project) {FactoryGirl.create(:project, :add_modules => ['easy_crm'])}
  let(:easy_crm_case) {FactoryGirl.create(:easy_crm_case, :project => project)}
  let(:contact_cf) {FactoryGirl.create(:easy_contact_custom_field)}
  let(:activity) { FactoryGirl.create(:time_entry_activity, projects: [project]) }
  let(:status) { FactoryBot.create(:easy_crm_case_status) }

  let(:easy_crm_case_create_params) {
    {
     easy_crm_case: {
       name: 'crm',
       project_id: project.id,
       easy_crm_case_status_id: status.id
     },
     project_id: project.id,
     format: 'json'
    }
  }

  render_views

  it 'should check new' do
    get :new
    assert_response :success
  end

  it 'should check edit' do
    get :edit, :params => {:id => easy_crm_case.id}
    assert_response :success
  end

  it 'should check show' do
    get :show, :params => {:id => easy_crm_case.id}
    assert_response :success
  end

  it 'should create crm' do
    expect{ post :create, :params => easy_crm_case_create_params }.to change{ EasyCrmCase.count }.by(1)
    expect( response ).to be_successful
  end

  describe '#update' do
    it 'set next_action' do
      put :update, params: { id: easy_crm_case.id, easy_crm_case: { next_action: Date.today + 2.days } }
      easy_crm_case.reload
      expect(easy_crm_case.next_action).to eq(Date.today + 2.days)
      expect(response).to redirect_to(easy_crm_case_path(easy_crm_case))
    end

    it 'log spent time' do
      expect { put :update, params: { id: easy_crm_case.id,
                                      easy_crm_case: { next_action: Date.today + 2.days },
                                      time_entry: { hours: 5, activity_id: activity.id } }
      }.to change(TimeEntry, :count).by(1)
    end
  end

  it 'index' do
    easy_crm_case
    get :index
    expect( response ).to be_successful
  end

  it 'index sorted by contact cf' do
    easy_crm_case
    get :index, :params => {:set_filter => '1', :sort => "easy_contacts.cf_#{contact_cf.id}"}
    expect( response ).to be_successful
  end

  it 'index show main contact cf' do
    easy_crm_case
    get :index, params: {set_filter: '1', column_names: ["main_easy_contacts.cf_#{contact_cf.id}"]}
    expect( response ).to be_successful
  end

  it 'index grouped by project' do
    easy_crm_case
    get :index, :params => {:set_filter => '1', :group_by => ['project']}
    expect( response ).to be_successful
    get :index, :params => {:set_filter => '1', :group_by => ['project'], :group_to_load => [easy_crm_case.project_id.to_s]}, :xhr => true
    expect( response ).to be_successful
    expect( response.body ).to include(easy_crm_case.project.to_s)
  end

  it 'export cases to xlsx' do
    easy_crm_case
    get :index, :params => {:format => 'xlsx', set_filter: '0', easy_query: {columns_to_export: 'all'}}
    expect( response ).to be_successful
  end

  it 'export cases to csv' do
    easy_crm_case
    get :index, :params => {:format => 'csv', set_filter: '0', easy_query: {columns_to_export: 'all'}}
    expect( response ).to be_successful
  end

  it 'export cases to pdf' do
    easy_crm_case
    get :index, :params => {:format => 'pdf', set_filter: '0', easy_query: {columns_to_export: 'all'}}
    expect( response ).to be_successful
  end

  it 'check bulk edit from easy crm case show' do
    get :bulk_edit, :params => {:id => easy_crm_case.id}
    expect( response ).to be_successful
  end

  it 'context menu' do
    get :context_menu, :params => {:ids => [easy_crm_case.id]}
    expect( response ).to be_successful
  end

  context 'notifications' do
    let(:own_easy_crm_case_create_params) {
      p = easy_crm_case_create_params.dup
      p[:easy_crm_case]['author_id'] = User.current.id
      p
    }

    before(:each) { ActionMailer::Base.deliveries = [] }

    context 'easy_crm_case_added' do
      around(:each) do |example|
        with_settings(:notified_events => ['easy_crm_case_added']) do
          with_deliveries do
            example.run
          end
        end
      end

      it 'create' do
        with_user_pref('no_self_notified' => '0') do
          post :create, :params => own_easy_crm_case_create_params
          expect(ActionMailer::Base.deliveries.size).to eq(1)
        end
      end

      it 'no notifications ever' do
        with_user_pref('no_notification_ever' => '1') do
          post :create, :params => own_easy_crm_case_create_params
          expect(ActionMailer::Base.deliveries.size).to eq(0)
        end
      end

      it 'no self notified' do
        with_user_pref('no_self_notified' => '1') do
          post :create, :params => own_easy_crm_case_create_params
          expect(ActionMailer::Base.deliveries.size).to eq(0)
        end
      end
    end
  end

  context 'easy invoice creation', :logged => :admin do
    let!(:project) {FactoryGirl.create(:project, :add_modules => ['easy_crm', 'easy_invoicing'])}
    let!(:easy_contact_supplier) { FactoryGirl.create(:easy_contact, :with_address_from_eu) }
    let!(:easy_contact_client) { FactoryGirl.create(:easy_contact, :with_address_from_eu) }
    let!(:easy_invoice_status) { FactoryGirl.create(:easy_invoice_status) }
    let!(:easy_invoice_sequence) { FactoryGirl.create(:easy_invoice_sequence) }
    let!(:easy_invoice_pm) { FactoryGirl.create(:easy_invoice_payment_method) }
    let!(:easy_crm_case_status) { FactoryGirl.create(:easy_crm_case_status, is_default: true) }

    let(:easy_crm_case_with_easy_invoice_create_params) {
      easy_crm_case = FactoryGirl.build(:easy_crm_case, :project => project, :easy_crm_case_status => easy_crm_case_status)
      p = {:easy_crm_case => easy_crm_case.attributes, :project_id => project.id, :format => 'json'}
      p[:easy_crm_case]['author_id'] = User.current.id
      p[:easy_crm_case]['easy_contact_ids'] = [easy_contact_client.id]
      p[:easy_invoice] = {'client_street' => 'street', 'client_city' => 'city', 'client_postal_code' => '123456', 'client_country' => 'CZ'}
      p
    }

    let(:settings) do
      {'easy_crm_invoice_settings' =>
        [
          {
            'easy_crm_case_status_id' => easy_crm_case_status.id.to_s,
            'easy_invoice_status_id' => easy_invoice_status.id.to_s
          }
        ],
        'easy_invoicing_easy_invoice_sequence_id' => easy_invoice_sequence.id.to_s,
        'easy_invoicing_supplier_id' => easy_contact_supplier.id.to_s
      }
    end

    it 'create' do
      with_easy_settings(settings) do
        post :create, :params => easy_crm_case_with_easy_invoice_create_params
        expect(assigns(:easy_invoice)).not_to be_nil
        expect(assigns(:easy_invoice).errors.messages).to be_blank
        expect(assigns(:easy_invoice)).not_to be_new_record
        expect(assigns(:easy_invoice).client_country).to eq 'CZ'
        expect(response).to be_successful
      end
    end
  end if Redmine::Plugin.installed?(:easy_invoicing)

  it 'autolink easy_crm_cases' do
    with_settings({'text_formatting' => 'HTML'}) do
      easy_crm_case = FactoryGirl.create(:easy_crm_case)
      easy_crm_case.update_column(:description, "<p>easy_crm_case##{easy_crm_case.id}</p><p>easy_crm_case:\"#{easy_crm_case.name}\"</p><p>:\"#{easy_crm_case.name}\"</p>")
      get :show, :params => {:id => easy_crm_case.id}
      assert_response :success
      assert_select '.easy-entity-details-description' do
        assert_select 'a.easy_crm_case', :count => 2
      end
    end
  end

  context 'api' do
    render_views

    it '#index' do
      FactoryGirl.create_list(:easy_crm_case, 5, project: project)
      get :index, params: { format: :json }
      expect(response).to be_successful
    end

    it '#show' do
      get :show, params: { format: :json, id: easy_crm_case.id }
      expect(response).to be_successful
    end
  end



  end
