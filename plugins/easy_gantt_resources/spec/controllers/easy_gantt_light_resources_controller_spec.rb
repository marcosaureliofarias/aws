require 'easy_extensions/spec_helper'

describe EasyLightResourcesController, logged: :admin do

  context '#index' do
    around(:each) do |example|
      with_settings(rest_api_enabled: 1) { example.run }
    end

    render_views

    let!(:tracker) { FactoryBot.create(:bug_tracker, issue_custom_fields: [issue_cf]) }
    let!(:issue_cf) { FactoryBot.create(:issue_custom_field, is_for_all: true) }
    let!(:project) { FactoryBot.create(:project, add_modules: ['easy_gantt', 'easy_gantt_resources'], number_of_issues: 0, trackers: tracker, issue_custom_fields: [issue_cf]) }
    let!(:issue) { FactoryBot.create(:issue, tracker: tracker, project: project) }
    let!(:easy_gantt_resource) { FactoryBot.create(:easy_gantt_resource, issue: issue) }

    it 'with custom fields' do
      get :index, params: {set_filter: '1', column_names: EasyLightResourceQuery.new.available_columns.map{|c| c.name.to_s}}
      expect(response).to be_successful
      expect(assigns(:entities).count).to eq(1)
    end
  end
end
