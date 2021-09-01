class EasyAssetsController < ApplicationController

  skip_before_action :check_if_login_required

  def typography
    respond_to do |format|
      if File.exists?(file_path)
        format.css { send_file file_path }
      else
        format.any { head 404 }
      end
    end
  end

  private

  def file_path
    assets_path = Redmine::Plugin.find(:easy_extensions).assets_directory
    File.join(assets_path, '/stylesheets/typography.css')
  end

end
