require "easy_extensions/spec_helper"

RSpec.feature "EasyInstantMessaging", js: true, logged: :admin do

  def get_chat_option(name)
    page.execute_script %Q{return window.EasyInstantMessenger.settings("#{name}")}
  end

  scenario "Increase default time interval based on tenancy" do
    EasyInstantMessages.default_refresh_time = 60
    visit "/"
    expect(get_chat_option('defaultTime')).to be < 90 * 1000

    if Redmine::Plugin.installed?(:easy_hosting_services)
      EasyInstantMessages.default_refresh_time = 140
      visit "/"
      expect(get_chat_option('defaultTime')).to be > 120 * 1000
    end
  end

end