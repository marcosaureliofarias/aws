require 'easy_extensions/spec_helper'

RSpec.describe 'easy_queries/_form_chart_settings', logged: :admin do

  let(:project) { FactoryBot.create(:project, number_of_issues: 0, number_of_members: 0, number_of_issue_categories: 0, number_of_subprojects: 0) }
  let(:status1) { FactoryBot.create(:issue_status) }
  let(:status2) { FactoryBot.create(:issue_status) }
  let(:issue1_1) { FactoryBot.create(:issue, status: status1, project: project) }
  let(:issue2_1) { FactoryBot.create(:issue, status: status2, project: project) }
  let(:issue2_2) { FactoryBot.create(:issue, status: status2, project: project) }

  it 'render partial' do
    issue1_1; issue2_1; issue2_2

    query = EasyIssueQuery.new;
    query.group_by       = ['status']
    query.chart_settings = {
        'axis_x_column'    => 'status',
        'axis_y_column'    => 'estimated_hours',
        'axis_y_type'      => 'count',
        'primary_renderer' => 'bar',
        'bar_limit'        => '1',
        'long_tail'        => '1'
    }

    presenter        = view.present(query)
    presenter.output = 'chart'
    outputs          = presenter.outputs.outputs
    chart_output     = outputs.find { |o| o.key == 'chart' }

    api = EasyExtensions::Views::Builders::LocalJson.new
    chart_output.render_json_data(api)

    data = api.__to_hash[:all_data].map! do |item|
      item.fetch_values(:name, :values)
    end

    expect(data).to eq(
                        [
                            [status2.name, 2.0],
                            [view.l(:label_long_tail), 1.0]
                        ]
                    )
  end

end
