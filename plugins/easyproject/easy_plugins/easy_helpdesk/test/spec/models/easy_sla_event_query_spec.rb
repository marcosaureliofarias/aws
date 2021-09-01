require 'easy_extensions/spec_helper'

describe EasySlaEventQuery, logged: :admin do
  subject(:query) { described_class.new }

  let(:easy_sla_event) { FactoryBot.create(:easy_sla_event) }
  let(:project_cf) { FactoryBot.create(:project_custom_field, name: 'testik', field_format: 'string') }

  let(:project_with_cv) {
    project_cf
    project = easy_sla_event.issue.project
    project.project_custom_fields = [project_cf]
    project.custom_field_values = { project_cf.id.to_s => 'test1' }
    project.save
    project
  }

  it 'project cf' do
    project_with_cv

    query.add_filter("issues.project_cf_#{project_cf.id}", '=', 'test2')
    expect(query.entities.to_a).to be_empty
    query.add_filter("issues.project_cf_#{project_cf.id}", '=', 'test1')
    expect(query.entities.to_a).to eq([easy_sla_event])
    query.add_filter("issues.project_cf_#{project_cf.id}", '!', 'test1')
    expect(query.entities.to_a).to be_empty
  end

  context 'when filtering by issue status' do
    let(:sla_event_issue_status) { easy_sla_event.issue_status.id }

    it 'correctly includes results with issue status' do
      query.add_filter('issue_status_id', '=', sla_event_issue_status)

      expect(query.entities.to_a).to include easy_sla_event
    end

    it 'correctly excludes results with issue status' do
      query.add_filter('issue_status_id', '!', sla_event_issue_status)

      expect(query.entities.to_a).not_to include easy_sla_event
    end
  end
end
