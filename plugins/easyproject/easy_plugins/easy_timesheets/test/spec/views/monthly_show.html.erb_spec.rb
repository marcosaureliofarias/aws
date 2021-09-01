require 'easy_extensions/spec_helper'

describe 'easy_timesheets/monthly_show', type: :view do
  subject { spy('EasyTimesheet', period: 'month', start_date: Date.new(2018, 11, 1), end_date: Date.new(2018, 11, 30)) }

  it 'check days count' do
    with_easy_settings(easy_timesheets_custom_field_overtime_id: 1) do
      allow(view).to receive(:render_timesheets_breadcrumb).and_return('')
      assign(:easy_timesheet, subject)
      assign(:day_range, subject.start_date..subject.end_date)
      stub_template 'easy_timesheet_rows/_row' => 'stubbed partial'
      render

      expect(rendered).to have_css('.table-monthly')
      expect(rendered).to have_css('.day-number', count: 30)
    end
  end
end
