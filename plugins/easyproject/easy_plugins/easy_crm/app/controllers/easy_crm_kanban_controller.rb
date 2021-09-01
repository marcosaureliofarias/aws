class EasyCrmKanbanController < ApplicationController
  before_action :find_project, if: proc { !params[:id].blank? }
  before_action :authorize_global
  before_action proc { flash.clear}

  include_query_helpers
  helper :easy_crm
  include EasyCrmHelper
  helper :easy_setting
  include EasySettingHelper
  helper :easy_icons
  helper :custom_fields
  include CustomFieldsHelper

  def show
    retrieve_query(EasyCrmCaseQuery)
    @query.display_filter_group_by_on_index = false
    @query.display_filter_sort_on_index = true
    @query.display_filter_columns_on_index = false
    @query.display_load_groups_opened = false
    @query.display_show_sum_row = false

    @limit = per_page_option
    offset = (params[:page].to_i - 1) * @limit if params[:page]

    @kanban_columns = []
    easy_setting = easy_crm_case_kanban_project_settings
    easy_setting = [easy_setting[params[:kanban_column].to_i]] if params[:kanban_column]
    @query.column_names = easy_setting.collect { |x| x['sum_column'].try(:to_sym) }
    easy_setting.each_with_index do |setting, key|
      @query.add_filter('easy_crm_case_status_id', '=', setting['easy_crm_case_statuses'])
      sum_column = setting['sum_column'].present? ? @query.columns.detect { |x| x.name == setting['sum_column'].to_sym } : nil
      @kanban_columns << {
        name: setting['name'],
        sum_column: sum_column,
        sum: sum_column && sum_column.sumable? ? @query.entity_sum(sum_column) : nil,
        count: @query.entity_count,
        entities: @query.entities(offset: offset.to_i, limit: @limit, preload: [:project, {easy_contacts: :easy_contact_type}, :easy_crm_case_status, assigned_to: (Setting.gravatar_enabled? ? :email_address : :easy_avatar), external_assigned_to: (Setting.gravatar_enabled? ? :email_address : :easy_avatar)]),
        drop_in_status: setting['drop_in_status'],
        position: params[:kanban_column].presence || key
      }
    end
    @kanban_column = @kanban_columns.first if @kanban_columns.count == 1

    @entity_count = @kanban_columns.map { |column| column[:count] }.max.to_i
    @max_pages = @kanban_columns.map { |column| (column[:count] / @limit).ceil }

    @query.delete_available_filter('easy_crm_case_status_id')

    respond_to do |format|
      format.html {
        if request.xhr? && @kanban_column
            render partial: 'easy_crm_kanban/kanban_column', locals: {column: @kanban_column, position: @kanban_column[:position]}
        end
      }
    end
  end

  def settings
    @all_statuses = EasyCrmCaseStatus.sorted
    @easy_crm_kanban_settings = easy_crm_case_kanban_project_settings
  end

  def save_settings
    if (settings = params[:easy_setting].delete(:easy_crm_case_kanban_project_settings))
      params[:easy_setting][:easy_crm_case_kanban_project_settings] = []; statuses = []
      settings.each do |_, attributes|
        if (easy_crm_statuses = Array(attributes['easy_crm_case_statuses']).select(&:present?)).present?
          statuses.concat easy_crm_statuses
          params[:easy_setting][:easy_crm_case_kanban_project_settings] << attributes
        end
      end
      if statuses.uniq.length == statuses.length && statuses.any?
        EasySetting.delete_key(:easy_crm_case_kanban_project_settings, @project)
        save_easy_settings(@project)
        @easy_crm_kanban_settings = EasySetting.value('easy_crm_case_kanban_project_settings') || []
        flash[:notice] = l(:notice_successful_update)
      else
        @easy_crm_kanban_settings = params[:easy_setting][:easy_crm_case_kanban_project_settings]
        flash[:error] = statuses.any? ? l(:label_easy_crm_kanban_status_not_uniq) : l(:label_statuses_not_selected)
      end
    end
    @all_statuses = EasyCrmCaseStatus.all.sorted
    if @project
      render :settings
    else
      redirect_back_or_default easy_crm_settings_global_path(tab: 'easy_crm_kanban_settings')
    end
  end

  def assign_entity
    easy_crm_case = EasyCrmCase.find(params[:easy_crm_case_id])
    if easy_crm_case.editable?
      easy_crm_case.init_journal(User.current)
      easy_crm_case.easy_crm_case_status = EasyCrmCaseStatus.find(params[:easy_crm_case_status_id])
      easy_crm_case.save(validate: false)

      respond_to do |format|
        format.all { head :ok }
      end
    else
      render_403
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
