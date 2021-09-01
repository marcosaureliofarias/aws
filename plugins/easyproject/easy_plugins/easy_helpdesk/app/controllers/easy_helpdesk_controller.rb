class EasyHelpdeskController < ApplicationController
  layout 'admin'

  before_action :authorize_global, only: [:settings]

  helper :easy_rake_tasks
  include EasyRakeTasksHelper
  helper :easy_helpdesk_projects
  include EasyHelpdeskProjectsHelper
  helper :easy_setting
  include EasySettingHelper

  EasyExtensions::EasyPageHandler.register_for(self, {
    page_name: 'easy-helpdesk-overview',
    path: proc { easy_helpdesk_path(t: params[:t]) },
    show_action: :index,
    edit_action: :layout
  })

  def settings
    save_easy_settings if request.put?
    @easy_helpdesk_sender = EasySetting.value('easy_helpdesk_sender')

    respond_to do |format|
      format.html
    end
  end

end
