class EasyMoneyPeriodicalEntitiesController < ApplicationController

  menu_item :easy_money

  before_action :find_project, :only => [:project_index, :toggle_entities_overview]
  before_action :find_project_by_project_id, :only => [:entity_bulk_update]
  before_action :find_easy_money_periodical_entity, :only => [:show]
  #  before_action :find_entity, :only => [:toggle_entities_overview]

  helper :easy_query
  include EasyQueryHelper
  helper :easy_money
  include EasyMoneyHelper
  helper :attachments
  include AttachmentsHelper
  helper :custom_fields
  include CustomFieldsHelper
  helper :projects
  include ProjectsHelper
  helper :sort
  include SortHelper

  def project_index
    if @project.easy_money_periodical_entities.empty?
      empe_pb = EasyMoneyPeriodicalEntityProjectBooking.create!(:entity => @project, :name => 'Booking', :column_idx => 0)
      empe_b = EasyMoneyPeriodicalEntityBacklog.create!(:entity => @project, :name => 'Backlog', :column_idx => 0)
      empe_i = EasyMoneyPeriodicalEntityInvoiced.create!(:entity => @project, :name => 'Invoiced', :column_idx => 1)

      empe_wpt = EasyMoneyPeriodicalEntityWpt.create!(:entity => @project, :name => 'Production Total', :column_idx => 1)
      empe_wpt_op = EasyMoneyPeriodicalEntityWptOwnProduction.create!(:entity => @project, :name => 'Internal Production', :column_idx => 1, :parent_id => empe_wpt.id)
      empe_wp_is = EasyMoneyPeriodicalEntityWptIntercompanySubcontract.create!(:entity => @project, :name => 'Intercompany subcontract', :column_idx => 1, :parent_id => empe_wpt.id)
      empe_wp_es = EasyMoneyPeriodicalEntityWptExternalSubcontract.create!(:entity => @project, :name => 'External subcontract', :column_idx => 1, :parent_id => empe_wpt.id)

      empe_wip = EasyMoneyPeriodicalEntityWip.create!(:entity => @project, :name => 'WIP', :column_idx => 1)

      empe_gm = EasyMoneyPeriodicalEntityGm.create!(:entity => @project, :name => 'Gross margin', :column_idx => 1)
      empe_gm_op = EasyMoneyPeriodicalEntityGmOwnProduction.create!(:entity => @project, :name => 'Internal Production', :column_idx => 1, :parent_id => empe_gm.id)
      empe_gm_is = EasyMoneyPeriodicalEntityGmIntercompanySubcontract.create!(:entity => @project, :name => 'Intercompany subcontract', :column_idx => 1, :parent_id => empe_gm.id)
      empe_gm_es = EasyMoneyPeriodicalEntityGmExternalSubcontract.create!(:entity => @project, :name => 'External subcontract', :column_idx => 1, :parent_id => empe_gm.id)
    end

    @edit = false
    @entities = @project.easy_money_periodical_entities.roots.sorted_by_position.group_by(&:column_idx)
    @period_date = (Date.today - 1.month).end_of_month
  end

  def index
    retrieve_query(EasyMoneyPeriodicalEntityQuery)
    sort_init(@query.sort_criteria.empty? ? [] : @query.sort_criteria)
    sort_update(@query.sortable_columns)

    prepare_easy_query_render(nil, limit: nil)

    if request.xhr? && !@entities
      render_404
      return false
    end

    respond_to do |format|
      format.html {
        render_easy_query_html
      }
      format.api
      format.csv  { send_data(export_to_csv(@entities, @query), :filename => get_export_filename(:csv, @query))}
      format.pdf  {
        send_file_headers! :type => 'application/pdf', :filename => get_export_filename(:pdf, @query)
        render 'easy_money_base_items/index'
      }
      format.xlsx { send_data(export_to_xlsx(@entities, @query), :filename => get_export_filename(:xlsx, @query))}
    end
  end

  def show
    @stacked = @easy_money_periodical_entity.children.any?
    @start_date = params[:start_date].to_date if params[:start_date]
    @start_date ||= Date.today.beginning_of_year
    @end_date = params[:end_date].to_date if params[:end_date]
    @end_date ||= Date.today.end_of_year
    @chart_ticks = 0.upto(11).collect{|idx| l(:abbr_month_names, :scope => :date)[idx + 1]}

    if @stacked
      @chart_data, @chart_series = [], []

      @easy_money_periodical_entity.children.each do |empe_child|
        last_empri = empe_child.easy_money_periodical_entity_items.sorted_by_period.first

        @chart_data << 0.upto(11).collect do |idx|
          current_period = @start_date.end_of_month + idx.month

          if last_empri.nil? || last_empri.period_date.end_of_month < current_period
            0.0
          else
            empe_child.price_until(current_period).to_f
          end
        end

        @chart_series << empe_child.name
      end
    else
      last_empri = @easy_money_periodical_entity.easy_money_periodical_entity_items.sorted_by_period.first

      @chart_data = [
        0.upto(11).collect do |idx|
          current_period = @start_date.end_of_month + idx.month

          if last_empri.nil? || last_empri.period_date.end_of_month < current_period
            0.0
          else
            @easy_money_periodical_entity.price_until(current_period).to_f
          end
        end]

      @chart_series = [@easy_money_periodical_entity.name]
    end

    respond_to do |format|
      format.html
    end
  end

  def toggle_entities_overview
    @period_date = begin; params['period_date'].to_date; rescue; (Date.today - 1.month).end_of_month; end
    @edit = (params[:edit] == '1')
    @entities = @project.easy_money_periodical_entities.roots.sorted_by_position.group_by(&:column_idx)

    respond_to do |format|
      format.js
    end
  end

  def entity_bulk_update
    @period_date = begin; params['period_date'].to_date; rescue; Date.today; end

    if @period_date == @period_date.end_of_month
      if params['easy_money_periodical_entities']
        params['easy_money_periodical_entities'].dup.each do |attrs|
          entity_id = attrs.delete('id')
          empe = EasyMoneyPeriodicalEntity.where(:id => entity_id).first if !entity_id.blank?
          next if empe.nil?

          attrs['period_date'] = params['period_date']

          new_empei = empe.easy_money_periodical_entity_items.where(:period_date => @period_date).first
          new_empei ||= empe.easy_money_periodical_entity_items.build(:author => User.current)
          new_empei.safe_attributes = attrs
          new_empei.save
        end

        @project.recalculate_easy_money_periodical_entities(@period_date)
      end
    else
      @msg = 'Period must be end of month'
    end

    @edit = false
    @entities = @project.easy_money_periodical_entities.roots.sorted_by_position.group_by(&:column_idx)

    respond_to do |format|
      format.js
    end
  end

  private

  def find_easy_money_periodical_entity
    @easy_money_periodical_entity = EasyMoneyPeriodicalEntity.find(params[:id])
    @project = @easy_money_periodical_entity.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
