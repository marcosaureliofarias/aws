# encoding: utf-8
require 'easy_extensions/spec_helper'

feature Encoding, logged: :admin do
  it 'should preserve proper utf-8 encoding' do
    with_settings({ 'text_formatting' => 'HTML' }) do
      issue = FactoryGirl.create(:issue, :description => '<p>ěščřžýáíéдьявольскиеоды</p>')
      visit issue_path(issue)
      within find('#show_issue_description') do
        expect(page).to have_content('ěščřžýáíéдьявольскиеоды')
      end
    end
  end

  it 'should strip unsafe tags' do
    with_settings({ 'text_formatting' => 'HTML' }) do
      issue = FactoryGirl.create(:issue, :description => '<p>text</p><script type="text/javascript"></script><p>text</p>')
      visit issue_path(issue)
      within find('#show_issue_description') do
        expect(page).to(have_content('<p>') && have_content('text'))
        expect(page).not_to have_content('<script')
      end
    end
  end

  it 'nokogiri truncate' do
    text = '<ul><li>Issued By:&nbsp;Adxabagahrdghf &amp; Agnuhte zohprnu SCC</li>
      <li>Issued&nbsp;To:&nbsp;Aagtjn A. Fole GroHefsdorax Focpofafion</li><li>Insured:&nbsp;Martan C. Uole</li>
	    <li>CI Benefit:&nbsp;$1,203,147</li><li>CI Premium:&nbsp;$2,462,842</li><li>ROP Rider:&nbsp;$494,285</li>
      <li>Risk Class: Afrardxx</li><li>Policy Currency: Canadian Dollar</li>
	    <li>Date of Issue:&nbsp;December 10, 2012</li></ul>'

    result = ApplicationController.new.view_context.truncate_html(text, 255)
    expect(result).to include('...')
    expect(result).not_to include('<li><li>')
  end

  context 'autolinks' do
    def template(token)
      "<p>#{token}</p><p>text #{token} text</p><table cellpadding='1' cellspacing='1'><tbody><tr><td>#{token}</td><td>#{token} #{token}</td></tr></tbody></table>"
    end

    ['http://link.cz', 'https://link.cz', 'https://www.link.cz', 'www.link.cz'].each do |link|
      it "replace #{link}" do
        with_settings({ 'text_formatting' => 'HTML' }) do
          description = template(link)
          issue       = FactoryGirl.create(:issue, :description => description)
          visit issue_path(issue)
          within find('#show_issue_description') do
            expect(page).to(have_css('a', :count => 5))
          end
        end
      end
    end

    ['file://127.0.0.1/~User/test.txt', 'smb://127.0.0.1/~User/test.txt'].each do |link|
      it "replace #{link}" do
        with_settings({ 'text_formatting' => 'HTML' }) do
          with_easy_settings({ 'ckeditor_autolink_file_protocols' => true }) do
            description = template(link)
            issue       = FactoryGirl.create(:issue, :description => description)
            visit issue_path(issue)
            within find('#show_issue_description') do
              expect(page).to(have_css('a', :count => 5))
            end
          end
        end
      end
    end

    it 'replace email' do
      with_settings({ 'text_formatting' => 'HTML' }) do
        email       = 'mail@test.com'
        description = template(email)
        issue       = FactoryGirl.create(:issue, :description => description)
        visit issue_path(issue)
        within find('#show_issue_description') do
          expect(page).to(have_css("a[href=\"mailto:#{email}\"]", :count => 5))
        end
      end
    end
  end
end
