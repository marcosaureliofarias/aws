class EasyCalculationController < ApplicationController
  menu_item :easy_calculation

  before_action :find_project, :authorize, :except => [:settings, :save_settings]
  before_action :require_admin, :only => [:settings, :save_settings]
  before_action :find_settings, :except => [:save_settings]
  before_action :find_calculation, :except => [:settings, :save_settings, :update, :order, :description]
  before_action :find_easy_calculation, :except => [:settings, :save_settings, :order, :save_to_easy_money]
  before_action :warnings, :only => [:show]

  helper :easy_setting
  include EasySettingHelper

  def show
    respond_to do |format|
      format.html
    end
  end

  def update
    @easy_calculation.safe_attributes = params[:easy_calculation]
    respond_to do |format|
      if @easy_calculation.save
        format.html { redirect_to( :action => 'show' ) }
        format.api { render_api_ok }
      else
        format.html { redirect_to( :action => 'show' ) }
        format.api { render_validation_errors(@easy_calculation) }
      end
    end
  end

  def settings
    respond_to do |format|
      format.html { render :layout => 'admin' }
    end
  end

  def save_settings
    settings = EasySetting.where(:name => 'calculation').first || EasySetting.new(:name => 'calculation')
    settings.value = {
      :tracker_ids => params[:calculation_settings][:tracker_ids].select(&:present?).collect{|id| id.to_i},
    }
    if settings.save
      flash[:notice] = l(:notice_successful_update)
    end
    find_settings
    render :action => 'settings', :layout => 'admin'
  end

  def description
    respond_to do |format|
      format.js
    end
  end

  def order
    reorder_to_position = params[:move_to] && params[:move_to][:reorder_to_position].to_i
    reorder_to_position -= params[:distance].to_i if params[:distance].present? && reorder_to_position
    if params[:phase]
      phase = Project.find(params[:phase][:id])
      phases = @project.children
      phases = [phase] if phases.blank?
      list = EasyCalculations::List.new(phases, phase)
      list.move_item_to(params[:phase][:move_to])
      list.reorder_to_position = reorder_to_position
    elsif params[:solution]
      if params[:solution][:type] == 'issue'
        solution = Issue.find(params[:solution][:id])
      else
        solution = EasyCalculationItem.find(params[:solution][:id])
      end
      solutions = solution.project.solution_entities
      list = EasyCalculations::List.new(solutions, solution)
      list.move_item_to(params[:solution][:move_to])
      list.reorder_to_position = reorder_to_position
    end

    respond_to do |format|
      format.html {redirect_to(:action => 'show')}
      format.api { render_api_ok }
    end
  end

  def save_to_easy_money
    render_404 unless Redmine::Plugin.installed?(:easy_money)
    redirect_to url_for({
        :controller => 'easy_money_expected_revenues',
        :action => 'new',
        :easy_money => {
          :revenue_type => 'expected_revenue',
          :entity_type => 'Project',
          :entity_id => @project,
          :price2 => @calculation.discounted_price_sum
        }
      })
  end

  private

  def find_settings
    @settings = EasySetting.value('calculation') || {}
    @settings[:show_in_easy_calculation] = params[:format] == nil || api_request?
  end

  def find_calculation
    @calculation = EasyCalculations::Calculation.new(@project, @settings)
  end

  def find_easy_calculation
    @easy_calculation = EasyCalculation.where(:project_id => @project.id).first
    @easy_calculation ||= EasyCalculation.new(:project_id => @project.id)
  end

  def warnings
    unless @calculation.show_phases?
      phase = @calculation.body[:phases].first
      if phase.try(:activities_disabled?)
        flash[:warning] = (l(:warning_calculation_phase_activites_flash) + ' ').html_safe
        flash[:warning] << view_context.link_to(l(:text_click_here_for_settings), settings_project_path(phase.project, :tab => 'activities'))
      end
    end
  end

end
