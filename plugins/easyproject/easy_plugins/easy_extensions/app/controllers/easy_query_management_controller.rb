class EasyQueryManagementController < ApplicationController
  before_action { |c| c.require_admin_or_lesser_admin(:easy_query_settings) }

  helper :easy_query
  include EasyQueryHelper
  helper :sort
  include SortHelper

  before_action :find_easy_query_type, only: [:edit, :update_default, :destroy_default]

  def edit
    @easy_query_types = []
    EasyQuery.registered_subclasses.keys.reject { |x| x == 'EasyEasyQueryQuery' }.each do |k|
      underscored = k.underscore
      @easy_query_types << [k, I18n.t("easy_query.name.#{underscored}", default: underscored)]
    end
    @easy_query_types.sort_by! { |_, y| y }

    @saved_filters = EasyQuery.where(type: @easy_query_type.name).sorted
    index_for_easy_query EasyEasyQueryQuery, [], { conditions: { type: params[:type] } }
  end

  def update_default
    default_filter                 = EasyDefaultQueryMapping.where(entity_type: params[:type], role_id: nil).first_or_initialize
    default_filter.safe_attributes = params[:easy_default_query_mapping]
    if default_filter.save
      respond_to do |format|
        format.api { render_api_ok }
      end
    else
      respond_to do |format|
        format.api { render_validation_errors(default_filter) }
      end
    end
  end

  def destroy_default
    EasyDefaultQueryMapping.where(entity_type: params[:type], role_id: nil).destroy_all
    respond_to do |format|
      format.html { redirect_to edit_easy_query_management_path(type: @easy_query_type.name) }
      format.api { render_api_ok }
    end
  end

  private

  def find_easy_query_type
    if params[:type].present?
      @easy_query_type = EasyQuery.get_subclass(params[:type])
      return render_404 unless @easy_query_type
      mappings                = EasyDefaultQueryMapping.preload(easy_query: :user).where(entity_type: params[:type]).order(:position).to_a
      @default_query_mappings = mappings.select { |x| !x.role_id.nil? }
      @default_filter         = mappings.detect { |x| x.role_id.nil? }
      params.delete(:query_id) if params[:query_id].present? && !EasyQuery.where(id: params[:query_id], type: 'EasyEasyQueryQuery').exists?
    else
      render_404
    end
  end


end
