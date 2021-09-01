module EasyMoneyEntitiesBudgetControllerConcern
  extend ActiveSupport::Concern

  included do
    before_action :find_project_by_project_id, if: -> { params[:project_id].present? }
    before_action :authorize_global, only: :index
    before_action :authorize, :check_modules, only: :project_index

    menu_item :easy_money

    helper :issues
    include IssuesHelper
    helper :easy_query
    include EasyQueryHelper
    helper :sort
    include SortHelper
    helper :custom_fields
    include CustomFieldsHelper
  end


  def index
    index_for_easy_query entity_money_query
  end

  def project_index
    index_for_easy_query entity_money_query
  end

  private

  def entity_money_query
    raise NotImplementedError
  end

  def required_project_module
    raise NotImplementedError
  end

  def check_modules
    render_404 unless @project.enabled_module_names.include? required_project_module
  end

end
