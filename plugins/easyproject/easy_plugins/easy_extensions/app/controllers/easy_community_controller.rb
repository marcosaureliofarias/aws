class EasyCommunityController < ApplicationController

  def log_in
    redirect_to("https://community.easyproject.com/users/auth/sso?auth_provider=easy_software_redmine_app&auth_url=#{Setting.protocol}://#{Setting.host_name}")
  end

end
