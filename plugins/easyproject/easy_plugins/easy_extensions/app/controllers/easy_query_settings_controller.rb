class EasyQuerySettingsController < ApplicationController
  layout 'admin'
  menu_item :easy_query_settings

  before_action { |c| c.require_admin_or_lesser_admin(:easy_query_settings) }
  before_action :prepare_query, :only => [:setting, :save]

  helper :easy_query_settings
  include EasyQuerySettingsHelper
  helper :custom_fields
  include CustomFieldsHelper
  helper :easy_query
  include EasyQueryHelper
  helper :sort
  include SortHelper
  helper :attachments
  include AttachmentsHelper

  def index
    @easy_query = default_easy_query
    default_settings
  end

  def setting
    default_settings
    render :action => 'index'
  end

  def save
    query_params = params.to_unsafe_hash.symbolize_keys
    settings     = query_params[:easy_query] if query_params[:easy_query]
    settings     = (settings || {}).dup.symbolize_keys

    update_default_filters(query_params[:tab], query_params)
    update_default_custom_formatting(query_params[:tab], query_params) if EasySetting.value('show_easy_custom_formatting')
    update_default_list_columns(query_params[:tab], settings[:column_names])
    update_default_grouped_by(query_params[:tab], settings[:group_by])
    update_default_sort(query_params[:tab], settings[:sort_criteria]) if settings[:sort_criteria]
    update_default_outputs(query_params[:tab], settings[:outputs]) if settings[:outputs]
    update_default_settings_criteria(query_params[:tab], settings)

    default_settings
    flash[:notice] = l(:notice_successful_update)
    render :action => 'index'
  end

  private

  def default_settings
    class_name = @easy_query.class.name.underscore
    settings   = ['show_sum_row', 'load_groups_opened', 'show_avatars',
                  'period_start_date', 'period_end_date', 'period_date_period',
                  'period_date_period_type', 'period_zoom']
    settings.each { |s| @easy_query.send("#{s}=", EasySetting.value("#{class_name}_#{s}")) }
    @easy_query.group_by     = EasySetting.value("#{class_name}_grouped_by")
    @easy_query.filters      = EasySetting.value("#{class_name}_default_filters") || {}
    @easy_query.outputs      = Array(EasySetting.value("#{class_name}_default_outputs"))
    @easy_query.column_names = EasySetting.value("#{class_name}_list_default_columns") || []
    @easy_query.settings     = EasySetting.value("#{class_name}_default_settings") || {}
  end

  def update_default_filters(easy_query, params)
    name                = "#{easy_query}_default_filters"
    @easy_query.filters = {}
    @easy_query.add_filters(params[:fields], params[:operators], params[:values])
    update_easy_settings(name, @easy_query.filters)
  end

  def update_default_custom_formatting(easy_query, params)
    name                          = "#{easy_query}_default_custom_formatting"
    @easy_query.custom_formatting = {}
    @easy_query.add_custom_formatting_from_params(params)
    update_easy_settings(name, @easy_query.custom_formatting)
  end

  def update_default_list_columns(easy_query, values)
    name = "#{easy_query}_list_default_columns"
    update_easy_settings(name, values)
  end

  def update_default_grouped_by(easy_query, values)
    name = "#{easy_query}_grouped_by"
    update_easy_settings(name, values)
  end

  def update_default_settings_criteria(easy_query, values)
    settings = [
        { :name => "#{easy_query}_show_sum_row", :value => values[:show_sum_row].try(:to_boolean) },
        { :name => "#{easy_query}_load_groups_opened", :value => values[:load_groups_opened].try(:to_boolean) },
        { :name => "#{easy_query}_show_avatars", :value => values[:show_avatars].try(:to_boolean) },
        { :name => "#{easy_query}_period_start_date", :value => values[:period_start_date] },
        { :name => "#{easy_query}_period_end_date", :value => values[:period_end_date] },
        { :name => "#{easy_query}_period_zoom", :value => values[:period_zoom] },
        { :name => "#{easy_query}_period_date_period_type", :value => values[:period_date_period_type] },
        { :name => "#{easy_query}_period_date_period", :value => values[:period_date_period] }
    ]

    settings << { :name => "#{easy_query}_default_settings", :value => values[:settings] } if values[:settings].present?

    settings.each { |s| update_easy_settings(s[:name], s[:value]) }
  end

  def update_default_sort(easy_query, values)
    sort_array, sort_string_s = Array.new, Array.new
    values.each do |_, sort|
      if sort[0].present? && sort[1].present?
        sort_array << [sort[0], sort[1]]
        sort_string_s << "#{sort[0]}:#{sort[1]}"
      elsif sort[0].present?
        sort_array << [sort[0], 'asc']
        sort_string_s << "#{sort[0]}:asc"
      end
    end

    update_easy_settings("#{easy_query}_default_sorting_array", sort_array)
    update_easy_settings("#{easy_query}_default_sorting_string_short", sort_string_s.join(','))
    update_easy_settings("#{easy_query}_default_sorting_string_long", sort_string_s.join(','))
  end

  def update_default_outputs(easy_query, values)
    update_easy_settings("#{easy_query}_default_outputs", Array(values) & @easy_query.available_outputs)
  end

  def update_easy_settings(name, values)
    easy_setting       = EasySetting.find_by(name: name) || EasySetting.new(name: name, value: [])
    easy_setting.value = values

    if !easy_setting.new_record? && values.blank? && values != false
      easy_setting.destroy
    else
      easy_setting.save
    end
  end

  def prepare_query
    @easy_query = EasyQuery.new_subclass_instance(params[:tab].classify) if params[:tab]
    @easy_query = default_easy_query if @easy_query.nil? || !@easy_query.is_a?(EasyQuery)
  end

  def default_easy_query
    EasyQuery.registered_subclasses.keys.first.constantize.new
  end

end
