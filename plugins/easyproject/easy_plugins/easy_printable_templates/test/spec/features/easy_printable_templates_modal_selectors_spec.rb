require 'easy_extensions/spec_helper'

feature 'easy printable templates', js: true, logged: :admin do

  let(:easy_printable_template) { FactoryGirl.create(:easy_printable_template) }

  it 'save to document modal display' do
    visit preview_easy_printable_template_path(easy_printable_template)
    page.find('a[id*="lookup_trigger"]').click
    wait_for_ajax
    expect(page).to have_selector('#easy_modal #modal_selector')
  end

end
