class EasyCrmController < ApplicationController

  menu_item :easy_crm
  default_search_scope :easy_crm_cases

  before_action :find_optional_project

  EasyExtensions::EasyPageHandler.register_for(self, {
    page_name: 'easy-crm-overview',
    path: proc { easy_crm_path(t: params[:t]) },
    show_action: :index,
    edit_action: :layout
  })

  def project_index
    render_action_as_easy_page(EasyPage.find_by(page_name: 'easy-crm-project-overview'), nil, @project.id,
                               project_easy_crm_path(t: params[:t]), false,
                               project: @project,
                               page_editable: User.current.allowed_to?(:manage_easy_crm_page, @project))
  end

  def project_layout
    render_action_as_easy_page(EasyPage.find_by(page_name: 'easy-crm-project-overview'), nil, @project.id,
                               project_easy_crm_path(t: params[:t]), true, project: @project)
  end

end
