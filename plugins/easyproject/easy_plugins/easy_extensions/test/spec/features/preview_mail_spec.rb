require 'easy_extensions/spec_helper'

feature 'preview mail', js: true, logged: :admin do

  let(:attachment) { FactoryGirl.build(:attachment) }

  def read_eml(filename)
    IO.read(File.join(File.dirname(__FILE__) + '/../../fixtures/files', filename))
  end

  scenario 'preview' do
    attachment.attributes = { :file => read_eml('inline_image_fullpath.eml'), :content_type => 'message/rfc822', :filename => 'test.eml' }
    attachment.save
    issue = attachment.container

    visit issue_path(issue)
    visit page.first('.list.attachments a')[:href]

    expect(page).to have_css('.message-preview')
    fn_regex = /arrow2.png/i
    expect(page).to have_content(fn_regex)
    page.find('a', :text => fn_regex).click
    expect(page).to have_css('img')
  end
end
