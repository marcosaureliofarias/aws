require_relative '../spec_helper'
RSpec.describe 'issues/show', logged: :admin, type: :view do

  let(:issue) { FactoryBot.create(:issue) }
  let(:journal) { FactoryBot.create(:last_comments_journal, journalized: issue, notes: "amen") }

  it 'view issues show details bottom' do
    journal
    render partial: 'issues/show_last_comments_on_issue/view_issues_show_details_bottom', locals: {issue: issue}

    expect(rendered).to have_text("#{format_date(journal.created_on)} amen")
  end

end
