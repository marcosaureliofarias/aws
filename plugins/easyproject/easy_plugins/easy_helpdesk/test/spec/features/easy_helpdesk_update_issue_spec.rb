require 'easy_extensions/spec_helper'

feature 'easy helpdesk send external mail', js: true, logged: :admin do

  let(:issue) { FactoryBot.create(:issue) }

  before do
    allow(issue).to receive(:disabled_core_fields).and_return([])
    allow(issue).to receive(:send_to_external_mails).and_return(true)
  end

  it 'unchecked send external mail flag' do
    visit edit_issue_path(issue)    
    expect(page.find('input#issue_send_to_external_mails')).not_to be_checked
  end
end

