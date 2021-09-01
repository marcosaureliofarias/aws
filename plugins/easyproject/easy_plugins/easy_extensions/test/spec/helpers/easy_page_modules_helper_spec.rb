require_relative '../spec_helper'

describe EasyPageModulesHelper, logged: :admin do
  let(:easy_query) { FactoryBot.create(:easy_issue_query) }
  let(:page_module) { FactoryBot.create(:easy_page_zone_module) }

  it 'easy_page_module_sort_header_tag' do
    link = helper.easy_page_module_sort_header_tag(page_module, easy_query, 'subject')
    expect(link).to include '<th', '<a', 'href', 'data-remote', '=subject'
  end

end
