class EasyBusinessDashboardsController < ApplicationController

  def labels_for_easy_global_filters
    respond_to do |format|
      format.json { render json: labels_for_easy_global_filters_hash }
    end
  end

  private

  def labels_for_easy_global_filters_hash
    %w[
      default_role_manager
      field_assigned_to_id
      field_author
      field_parent_project
      field_project
      field_root
      field_user
      field_version
      label_country
      label_date
      label_group
      label_period
      label_product
      label_salesman
    ].each_with_object({}) { |key, object| object[key] = I18n.t(key) }
  end

end
