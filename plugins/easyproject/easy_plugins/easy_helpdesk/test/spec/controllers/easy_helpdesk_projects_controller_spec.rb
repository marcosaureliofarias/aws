require 'easy_extensions/spec_helper'

describe EasyHelpdeskProjectsController, logged: :admin do
  let(:easy_helpdesk_project) { FactoryBot.create(:easy_helpdesk_project, keyword: 'testkeyword') }
  let(:from_easy_helpdesk_project_matching) { FactoryBot.create(:easy_helpdesk_project_matching, domain_name: 'easy@test.com') }

  render_views

  context 'find_by_email' do
    it 'from' do
      from_easy_helpdesk_project_matching

      get :find_by_email, params: { from: 'easy@test.com', format: 'json' }
      expect(response).to be_successful
      expect(json).to have_key(:easy_helpdesk_project)
    end

    it 'subject' do
      easy_helpdesk_project

      get :find_by_email, params: { subject: 'testkeyword', format: 'json' }
      expect(response).to be_successful
      expect(json).to have_key(:easy_helpdesk_project)
    end

    it 'no params' do
      easy_helpdesk_project

      get :find_by_email, params: { format: 'json' }
      expect(response.status).to eq(404)
    end
  end

  context 'index' do
    let(:lookup_settings) { {entity_type: 'Project', entity_attribute: 'link_with_name'} }
    let(:project_lookup) { FactoryBot.create(:project_custom_field, field_format: 'easy_lookup', settings: lookup_settings, is_for_all: true, show_on_list: true, is_filter: true) }

    it 'group by lookup' do
      easy_helpdesk_project
      get :index, params: { set_filter: '1', group_by: ["projects.cf_#{project_lookup.id}"] }
      expect(response).to be_successful
    end
  end

  context 'exports' do
    before(:each) { easy_helpdesk_project }

    it 'exports to xlsx' do
      get :index, params: { format: 'xlsx', set_filter: '0', easy_query: { columns_to_export: 'all' } }
      expect(response).to be_successful
      expect(response.content_type).to eq('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
    end

    it 'exports to csv' do
      get :index, params: { format: 'csv', set_filter: '0', easy_query: { columns_to_export: 'all' } }
      expect(response).to be_successful
      expect(response.content_type).to include('text/csv')
      expect(response.body).to include(easy_helpdesk_project.project.name)
    end
  end
end
