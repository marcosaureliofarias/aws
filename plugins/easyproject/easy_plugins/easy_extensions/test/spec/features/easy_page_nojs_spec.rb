require 'easy_extensions/spec_helper'

RSpec.describe 'Page tabs', type: :feature do
  include_context 'logged as admin'

  it 'Mobile tab' do
    tab1_name = 'First page tab'
    tab2_name = 'Second page tab'
    tab3_name = 'Third page tab'

    mobile_request_header = 'phone Mozilla/5.0 (Linux; Android 4.4.4; One Build/KTU84L.H4) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/33.0.0.0 Mobile Safari/537.36 [FB_IAB/FB4A;FBAV/28.0.0.20.16;]'

    my_page = EasyPage.find_by(page_name: 'my-page')
    tab1    = EasyPageUserTab.add(my_page, User.current, nil, name: tab1_name, mobile_default: false)
    tab2    = EasyPageUserTab.add(my_page, User.current, nil, name: tab2_name, mobile_default: true)
    tab3    = EasyPageUserTab.add(my_page, User.current, nil, name: tab3_name, mobile_default: false)

    #
    # By default, first tab is opened
    #
    visit home_path

    within('#easy_page_tabs') do
      expect(find_link(tab1_name)[:class]).to include('selected')
      expect(find_link(tab2_name)[:class]).not_to include('selected')
      expect(find_link(tab3_name)[:class]).not_to include('selected')
    end

    #
    # Second tab is marked as default for mobile
    #
    page.driver.header('User-Agent', mobile_request_header)
    visit home_path

    within('#easy_page_tabs') do
      expect(find_link(tab1_name)[:class]).not_to include('selected')
      expect(find_link(tab2_name)[:class]).to include('selected')
      expect(find_link(tab3_name)[:class]).not_to include('selected')
    end

    #
    # Third tab should have precedence over default tab
    #
    page.driver.header('User-Agent', mobile_request_header)
    visit home_path(t: tab3.position)

    within('#easy_page_tabs') do
      expect(find_link(tab1_name)[:class]).not_to include('selected')
      expect(find_link(tab2_name)[:class]).not_to include('selected')
      expect(find_link(tab3_name)[:class]).to include('selected')
    end
  end

end
