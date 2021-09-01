require 'easy_extensions/spec_helper'

RSpec.describe EasyExtensions::Export::Csv, logged: :admin do
  describe 'csv query export' do
    let(:params) { { outputs: [] } }
    let(:context) { IssuesController.new.view_context }

    subject(:export_result) { described_class.new(query, context).output }

    before do
      @expected_rows = []
      allow(Redmine::Export::CSV).to receive(:generate) do |_, &block|
        block.call(@expected_rows)
        @expected_rows
      end
    end

    it 'allowed exportable outputs' do
      query = EasyIssueQuery.new(outputs: ['list', 'calendar', 'report', 'kanban'])
      export = EasyExtensions::Export::Csv.new(query, context)
      expect(export.instance_variable_get(:@outputs)).to match_array(['list', 'report'])
    end

    context 'list output' do
      let!(:issue) { FactoryBot.create(:issue) }
      let(:column_names) { ['tracker', 'status', 'project'] }
      let(:query) {
        q = EasyIssueQuery.new
        q.from_params('set_filter' => '1', 'outputs' => ['list'], 'column_names' => column_names)
        q
      }

      it 'successfull export' do
        headers = [I18n.t(:field_tracker), I18n.t(:field_status), I18n.t(:field_project)]
        issue_row = [issue.tracker.name, issue.status.name, issue.project.name]
        expect(export_result).to match_array([match_array(headers), match_array(issue_row)])
      end
    end

    context 'report output' do
      let!(:issue) { FactoryBot.create(:issue, estimated_hours: 8) }
      let(:settings) { { report_group_by: ['status', 'tracker', 'priority'], report_sum_column: ['estimated_hours', ''] } }
      let(:query) {
        q = EasyIssueQuery.new
        q.from_params('set_filter' => '1', 'outputs' => ['report'], 'settings' => settings)
        q
      }

      it 'successfull export' do
        #            New                   Total
        #            Estimated time Count  Estimated time Count
        # Task  Low  8              1      8              1
        # Total      8              1      8              1
        top_group_headings = [nil, nil, issue.status.name, nil, I18n.t(:label_total)]
        top_sum_headings = [nil, nil, I18n.t(:field_estimated_hours), I18n.t(:field_count), I18n.t(:field_estimated_hours), I18n.t(:field_count)]
        issue_row = [issue.tracker.name, issue.priority.name, '8.00', 1, '8.00', 1]
        total_row = [I18n.t(:label_total), nil, '8.00', 1, '8.00', 1]
        expect(export_result).to match_array([match_array(top_group_headings), match_array(top_sum_headings), match_array(issue_row), match_array(total_row)])
      end
    end

    context 'report output without settings' do
      let!(:issue) { FactoryBot.create(:issue, estimated_hours: 8) }
      let(:query) {
        q = EasyIssueQuery.new
        q.from_params('set_filter' => '1', 'outputs' => ['report'])
        q
      }

      it 'successfull export' do
        expect(export_result).to be_blank
      end
    end
  end
end
