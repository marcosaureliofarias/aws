require 'easy_extensions/spec_helper'

feature 'external emails', :js => true, :js_wait => :long, :logged => :admin do
  let(:issue) { FactoryGirl.create(:issue) }

  scenario 'preview' do
    visit issue_preview_external_email_path(issue, :back_url => issue_path(issue))
    wait_for_ajax
    page.find('#external_mail_submit_buttons a.button').click
    expect(page).to have_css('#issue-detail')
  end
end
