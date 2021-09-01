class EasyPageTabsController < ApplicationController

  before_action :find_page

  def get_content
    @layout_style = @page.layout_path

    # page_tab
    # page
    # user = nil
    # entity_id = nil
    # back_url = nil
    # edit = false
    # page_context = {}
    render_action_as_easy_tab_content(@tab, @page, @user, @entity_id, params[:back_url], false, project: @project)
    render layout: false
  end

  private

  def find_page
    if params[:id].present?
      @tab       = EasyPageUserTab.preload(:page_definition, :user).find(params[:id])
      @page      = @tab.page_definition
      @user      = @tab.user
      @entity_id = @tab.entity_id
    elsif params[:page_id].present?
      @tab       = nil
      @page      = EasyPage.find(params[:page_id])
      @user      = User.find_by(id: params[:user_id])
      @entity_id = params[:entity_id]
    end

    if @entity_id.present?
      @project = Project.visible.find(@entity_id)
    end

    return render_404 if @page.nil?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
