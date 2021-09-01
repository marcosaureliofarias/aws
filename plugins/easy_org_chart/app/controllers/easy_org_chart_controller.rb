class EasyOrgChartController < ApplicationController
  helper :easy_org_chart

  before_action :require_admin, only: [:create, :show]

  def tree
    @easy_page_zone_module = params[:page_module_id] && EasyPageZoneModule.find_by(uuid: params[:page_module_id])
    root_node = @easy_page_zone_module && @easy_page_zone_module.settings['root_user_id'].present? && EasyOrgChartNode.where(user_id: @easy_page_zone_module.settings['root_user_id']).first

    unless root_node
      root_node = EasyOrgChartNode.roots.first
    end

    @easy_org_chart = root_node ? root_node.self_and_descendants.preload(:user) : []

    respond_to do |format|
      format.html { redirect_to easy_org_chart_path }
      format.json
    end
  end

  def create
    EasyOrgChartNode.create_nodes!(params[:easy_org_chart].try(:to_unsafe_hash))

    head 201
  end

  def users
    with_user_ids = params[:with_user_id].to_s.split(',')
    without_user_ids = params[:without_user_id].to_s.split(',')

    scope = User.active.easy_type_internal.sorted.with_easy_avatar.without_org_chart(*with_user_ids).where.not(id: without_user_ids)

    @users = params[:keywords].present? ? scope.like(params[:keywords]).limit(25) : scope.limit(100)

    respond_to do |format|
      format.html { head 200 }
      format.json
    end
  end

  private

  def require_admin
    require_admin_or_lesser_admin(:users)
  end
end
