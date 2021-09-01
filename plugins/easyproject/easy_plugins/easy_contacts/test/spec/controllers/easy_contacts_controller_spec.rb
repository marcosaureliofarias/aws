require 'easy_extensions/spec_helper'

describe EasyContactsController do

  let!(:contact) { FactoryGirl.create(:easy_contact) }
  let(:easy_contact_type) { FactoryBot.create(:easy_contact_type, is_default: false) }
  let(:easy_contact_custom_field) { FactoryGirl.create(:easy_contact_custom_field, contact_type_ids: [easy_contact_type.id]) }
  let(:grouped_query){ FactoryGirl.create(:easy_contact_query, :group_by => 'contact_groups') }
  let(:project) { FactoryGirl.create(:project) }

  context 'with admin user', logged: :admin do

    describe 'GET index' do
      render_views

      it 'renders classical query' do
        get :index
        expect( response ).to be_successful
      end

      it 'renders project query' do
        get :index, :params => {:project_id => project.id}
        expect( response ).to be_successful
      end

      it 'renders filtered query on project' do
        if Redmine::Plugin.installed?(:easy_crm)
          get :index, :params => {:project_id => project.id, :set_filter => '1', :'easy_crm_cases.author_id' => '=me'}
          expect( response ).to be_successful
        end
      end

      it 'renders grouped query' do
        get :index, :params => {:query_id => grouped_query.id}
        expect( response ).to be_successful
      end

      it 'exports index to pdf' do
        get :index, :params => {:format => 'pdf', set_filter: '0', easy_query: {columns_to_export: 'all'}}
        expect( response ).to be_successful
        expect( response.content_type ).to eq( 'application/pdf' )
      end

      it 'exports index to xlsx' do
        get :index, :params => {:format => 'xlsx', set_filter: '0', easy_query: {columns_to_export: 'all'}}
        expect( response ).to be_successful
        expect( response.content_type ).to eq( 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' )
      end

      it 'exports to csv' do
        get :index, :params => {:format => 'csv', set_filter: '0', easy_query: {columns_to_export: 'all'}}
        expect( response ).to be_successful
        expect( response.content_type ).to include( 'text/csv' )
      end

      it 'exports to atom' do
        get :index, :params => {:format => 'atom'}
        expect( response ).to be_successful
        expect( response.content_type ).to eq( 'application/atom+xml' )
      end

      it 'exports to json' do
        get :index, :params => {:format => 'json'}
        expect( response ).to be_successful
      end
    end

    describe 'show' do
      let(:easy_invoices) { FactoryGirl.build_list(:easy_invoice, 4, :client => easy_contact_with_relations, :supplier => easy_contact_with_relations, :easy_crm_case => easy_crm_case2) }
      let(:easy_crm_case) { FactoryGirl.create(:easy_crm_case) }
      let(:easy_crm_case2) { FactoryGirl.create(:easy_crm_case) }
      let(:easy_crm_case_cf) { FactoryGirl.create(:easy_crm_case_custom_field) }
      let(:easy_contact_cf) { FactoryGirl.create(:easy_contact_custom_field) }
      let(:subcontact) { FactoryGirl.create(:easy_contact, :parent_id => contact.id) }
      let(:easy_contact_with_relations) { FactoryGirl.create(:easy_contact, :easy_crm_cases => [easy_crm_case]) }

      render_views

      it 'renders contact detail with relations' do
        if Redmine::Plugin.installed?(:easy_crm) && Redmine::Plugin.installed?(:easy_invoicing)
          easy_crm_case_cf
          easy_invoices.each{|i| i.save(:validate => false) }
          with_easy_settings(:easy_invoice_query_list_default_columns => ['project', "easy_crm_cases.cf_#{easy_crm_case_cf.id}"]) do
            get :show, :params => {:id => easy_contact_with_relations}
            expect( response ).to be_successful
          end
        end
      end

      it 'renders contact detail with disabled custom field' do
        cf = easy_contact_cf
        contact.easy_contact_type.custom_fields << cf
        subcontact.easy_contact_type.custom_fields << cf
        contact.reload
        subcontact.reload
        subcontact.custom_field_values = {"#{cf.id}" => 'subvalue'}
        contact.custom_field_values = {"#{cf.id}" => 'convalue'}
        subcontact.save
        contact.save
        cf.disabled = true
        cf.save
        get :show, :params => {:id => subcontact.id}
        expect( response ).to be_successful
        get :show, :params => {:id => contact.id}
        expect( response ).to be_successful
      end
    end

    describe 'create' do
      render_views

      it 'assign private contact to me' do
        post :create, :params => {:easy_contact => {:firstname => 'test', :lastname => 'test', :private => '1'}, :assign_to_me => '1'}
        easy_contact = assigns(:easy_contact)
        expect(easy_contact.new_record?).to eq(false)
        expect(easy_contact.reload.user_ids).to include(User.current.id)
      end

      it 'return to lookup' do
        post :create, :params => {:format => :js, :easy_contact => {:firstname => 'test', :lastname => 'test'}, :return_to_lookup => '1'}
        expect(assigns(:easy_contact).new_record?).to eq(false)
        expect(response).to be_successful
      end

      it 'easy_external_id is in api response' do
        post :create, params: { easy_contact: { firstname: 'test', lastname: 'test', private: '1', easy_external_id: 'abcd' }, assign_to_me: '1', format: 'json' }
        easy_contact = assigns(:easy_contact)
        expect(easy_contact.new_record?).to eq(false)
        expect(easy_contact.easy_external_id).to eq('abcd')
        expect(response).to be_successful
        expect(JSON.parse(response.body)['easy_contact']['easy_external_id']).to eq('abcd')
      end
    end

    describe 'destroy contact' do
      it 'destroy' do
        contact
        expect {
          delete :destroy, :params => {:format => 'json', :id => contact.id}
        }.to change(EasyContact, :count).by(-1)
        expect(response).to be_successful
      end

      it 'destroy items' do
        contact
        expect {
          delete :destroy_items, :params => {:format => 'json', :ids => [contact.id]}
        }.to change(EasyContact, :count).by(-1)
        expect(response).to be_successful
      end
    end

    describe 'anonymize contact' do
      let(:easy_contact_type) { FactoryGirl.create(:easy_contact_type) }
      let(:easy_contact_cf_anonymized) { FactoryGirl.create(:easy_contact_custom_field, field_format: 'string', clear_when_anonymize: true, contact_types: [easy_contact_type]) }
      let(:easy_contact_cf_simple) { FactoryGirl.create(:easy_contact_custom_field, field_format: 'string', contact_types: [easy_contact_type]) }
      let(:contact1) { FactoryGirl.create(:easy_contact,
                                          type_id: easy_contact_type.id,
                                          custom_field_values: {
                                              easy_contact_cf_anonymized.id.to_s => 'anonymized',
                                              easy_contact_cf_simple.id.to_s => 'simple'
                                          })
      }

      it 'anonymize' do
        contact1
        post :anonymize, params: {id: contact1.id}
        contact1.reload
        expect(contact1.custom_field_value(easy_contact_cf_anonymized.id)).to be_nil
        expect(contact1.custom_field_value(easy_contact_cf_simple.id)).to eq 'simple'

        expect(response).to redirect_to(easy_contact_path(contact1))
      end

      it 'bulk anonymize' do
        contact1
        post :bulk_anonymize, params: {ids: [contact1.id]}
        contact1.reload
        expect(contact1.custom_field_value(easy_contact_cf_anonymized.id)).to be_nil
        expect(contact1.custom_field_value(easy_contact_cf_simple.id)).to eq 'simple'

        expect(response).to redirect_to(easy_contacts_path)
      end
    end

    context 'fields permissions', logged: true do
      let(:group) { FactoryGirl.create(:group) }
      let(:user) { FactoryGirl.create(:user, groups: [group]) }

      before(:each) do
        role = Role.non_member
        role.add_permission! :view_easy_contacts, :manage_easy_contacts
      end

      it 'author permitted' do
        contact
        get :index, params: {column_names: ["contact_name", "author"]}
        expect(response).to be_successful
        expect(assigns[:query].inline_columns.detect {|i| i.name == :author}.present?).to be true
      end

      it 'author forbidden' do
        contact
        with_easy_settings(easy_contact_author_id_allowed_user_ids: [user.id]) do
          get :index, params: {column_names: ["contact_name", "author"]}
        end
        expect(response).to be_successful
        expect(assigns[:query].inline_columns.detect {|i| i.name == :author}).to be nil
      end

      it 'assigned to permitted' do
        contact
        get :index, params: {column_names: ["contact_name", "assigned_to"]}
        expect(response).to be_successful
        expect(assigns[:query].inline_columns.detect {|i| i.name == :assigned_to}.present?).to be true
      end

      it 'assigned to forbidden' do
        contact
        with_easy_settings(easy_contact_assigned_to_id_allowed_group_ids: user.group_ids) do
          get :index, params: {column_names: ["contact_name", "assigned_to"]}
          expect(response).to be_successful
          expect(assigns[:query].inline_columns.detect {|i| i.name == :assigned_to}).to be nil
        end
      end


      it 'firstname to forbidden' do
        contact
        get :index, params: {column_names: ["contact_name", "author", "firstname", "lastname"]}
        expect(response).to be_successful
        expect(assigns[:query].inline_columns.detect {|i| i.name == :contact_name}).to be
        expect(assigns[:query].inline_columns.detect {|i| i.name == :firstname}).to be
        expect(assigns[:query].inline_columns.detect {|i| i.name == :lastname}).to be
      end

      it 'assigned to forbidden' do
        contact
        with_easy_settings(easy_contact_firstname_allowed_user_ids: [user.id]) do
          get :index, params: {column_names: ["contact_name", "author", "firstname", "lastname"]}
        end
        expect(response).to be_successful
        expect(assigns[:query].inline_columns.detect {|i| i.name == :contact_name}).to be nil
        expect(assigns[:query].inline_columns.detect {|i| i.name == :firstname}).to be nil
        expect(assigns[:query].inline_columns.detect {|i| i.name == :lastname}).to be
      end

    end

    it 'build_easy_contact_from_params updates status before caching custom fields' do
      params = {
        easy_contact: { type_id: easy_contact_type.id },
        id: contact.id
      }.with_indifferent_access

      expect(contact.visible_custom_field_values.map(&:custom_field)).not_to include(easy_contact_custom_field)
      patch :update_form, params: params
      expect(assigns[:easy_contact].visible_custom_field_values.map(&:custom_field)).to include(easy_contact_custom_field)
    end

    describe 'render_tabs' do
      it 'render_tab for easy_entity_activity' do
        get :render_tab, params: { id: contact, tab: 'easy_entity_activity' }
        expect(response).to be_successful
      end

      it 'render_tab for different modules' do
        get :render_tab, params: { id: contact, tab: 'unexisting_nonsense_tab' }
        expect(response).to have_http_status(404)
      end
    end

  end
end
