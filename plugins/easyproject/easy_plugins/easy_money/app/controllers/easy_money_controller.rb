class EasyMoneyController < ApplicationController

  menu_item :easy_money

  before_action :find_easy_money_project, except: [:index, :project_selector, :projects_to_move, :move_to_project]
  before_action :authorize, only: [:project_index]
  before_action :load_current_easy_currency_code, only: [:project_index, :inline_expected_profit, :inline_other_profit]

  EasyExtensions::EasyPageHandler.register_for(self, {
    page_name: 'easy-money-projects-overview',
    path: proc { easy_money_path(t: params[:t]) },
    show_action: :index,
    edit_action: :layout
  })

  def project_index
    @subprojects = @project.children.non_templates.
      joins("INNER JOIN projects as descendants ON descendants.lft > #{@project.lft} AND descendants.rgt < #{@project.rgt} AND descendants.lft >= projects.lft AND descendants.rgt <= projects.rgt").
      where(Project.allowed_to_condition(User.current, :view_easy_money, table_name: 'descendants')).distinct.sorted
  end

  def inline_expected_profit
    easy_money = @entity.easy_money(@current_easy_currency_code)

    render :partial => 'easy_money/inline_expected_profit', :locals => { :project => @project, :expected_profit => easy_money.expected_profit(@project.easy_money_settings.expected_count_price.to_sym), :easy_currency_code => @current_easy_currency_code }
  end

  def inline_other_profit
    easy_money = @entity.easy_money(@current_easy_currency_code)
    rate_type = EasyMoneyRateType.rate_type_cache(:name => @project.easy_money_settings.expected_rate_type)
    rate_type_id = rate_type.id if rate_type
    render :partial => 'easy_money/inline_other_profit', :locals => { :project => @project, :other_profit => easy_money.other_profit(@project.easy_money_settings.expected_count_price.to_sym, rate_type_id), :easy_currency_code => @current_easy_currency_code}
  end

  def projects_to_move
    @self_only = params[:term].blank?
    @projects = get_projects_to_move(params[:term], params[:term].blank? ? nil : 15)
    respond_to do |format|
      format.api
    end
  end

  def move_to_project
    easy_money_type = params[:easy_money_type].constantize rescue nil
    if params[:to_project_id].present? && easy_money_type
      @to_project = Project.find params[:to_project_id]
      @from_project = @to_project if params[:from_project_id].blank?
      @from_project ||= Project.find params[:from_project_id]

      if params[:ids].blank?
        flash[:error] = l(:error_easy_money_project_selector_select_values)
        # redirect_to :controller => "easy_money_#{params[:money_entity_type]}", :action => 'index', :project_id => @from_project.id
        redirect_to polymorphic_path([@from_project, easy_money_type]), :error => l(:error_easy_money_project_selector_select_values)
      else
        if User.current.allowed_to?(:easy_money_move, @from_project) && User.current.allowed_to?(:easy_money_move, @to_project)
          easy_money_type.where(:id => params[:ids]).to_a.each do |easy_money|
            easy_money.entity = @to_project
            easy_money.save
          end

          redirect_to polymorphic_path([@to_project, easy_money_type]), :notice => l(:notice_successful_update)
        else
          render_403
        end
      end
    else
      render_404
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def change_easy_money_type
    easy_money_type = params[:easy_money_type].constantize rescue nil
    return render_404 unless easy_money_type
    @project = Project.find params[:project_id] if params[:project_id].present?
    if params[:ids].blank?
      redirect_to polymorphic_path([@project, easy_money_type]), :error => l(:error_easy_money_project_selector_select_values)
    elsif User.current.allowed_to?(:easy_money_move, @project, :global => true)
      maps = EasyEntityAttributeMap.where(:entity_from_type => params[:easy_money_type], :entity_to_type => params[:easy_money_target_type])
      target = params[:easy_money_target_type].constantize rescue nil
      return render_404 unless target
      if maps.any?
        easy_money_type.where(:id => params[:ids]).each do |easy_money|
          new_easy_money = EasyExtensions::EasyEntityAttributeMappings::Mapper.map_entity(maps, easy_money, target.new(easy_money.attributes.except('easy_repeat_settings', 'id')))
          if easy_money.easy_is_repeating
            flash[:error] = l(:error_easy_money_cant_copy_repeating)
          elsif new_easy_money.save
            new_easy_money.attachments = easy_money.attachments.map do |attachment|
              attachment.copy(container: new_easy_money)
            end
            easy_money.destroy if params[:move].present?
            flash[:notice] = l(:notice_successful_update)
          else
            flash[:error] = new_easy_money.errors.full_messages.join('<br>'.html_safe)
          end
        end
      else
        flash[:error] = l(:error_easy_entity_attribute_map_invalid)
      end
      redirect_to polymorphic_path([@project, flash[:error].present? ? easy_money_type : target])
    else
      render_403
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def render_entity_select
    @selected_value = { id: @entity.id, name: @entity.to_s } if params[:entity_type] == @entity.class.to_s
    respond_to do |format|
      format.js
    end
  end

  private

  def get_projects_to_move(term = '', limit = nil)
    Project.active.non_templates.has_module(:easy_money).where(["#{Project.allowed_to_condition(User.current, :easy_money_move)} AND #{Project.table_name}.name like ?", "%#{term}%"]).reorder("#{Project.table_name}.lft").limit(limit).all
  end

end
