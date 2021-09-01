class EasyResourceDashboardController < ApplicationController

  before_action :find_easy_page, only: [:index, :layout]
  before_action :authorize_for_easy_page, only: [:index]
  before_action only: [:layout] do |c|
    c.send(:authorize_for_easy_page, true)
  end

  def index
    render_page
  end

  def layout
    render_page(true)
  end

  private

  def render_page(edit=false)
    back_url = easy_resource_dashboard_path(t: params[:t])
    render_action_as_easy_page(@page, nil, nil, back_url, edit)
  end

  def find_easy_page
    render_404 unless (@page = EasyPage.find_by(page_name: 'easy-resource-dashboard'))
  end

  def authorize_for_easy_page(edit=false)
    @authorized ||= if edit
      @page.editable?(authorized: authorize_global)
    else
      @page.visible?(authorized: authorize_global)
    end
  end
  helper_method :authorize_for_easy_page

end
