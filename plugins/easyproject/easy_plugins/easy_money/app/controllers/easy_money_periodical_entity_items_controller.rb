class EasyMoneyPeriodicalEntityItemsController < ApplicationController
  menu_item :easy_money

  before_action :find_easy_money_periodical_entity
  before_action :find_easy_money_periodical_entity_item, :only => [:edit, :update, :destroy]
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

  def new
    create_new_easy_money_periodical_entity_item

    respond_to do |format|
      format.js
    end
  end

  def create
    create_new_easy_money_periodical_entity_item

    if @easy_money_periodical_entity_item.save
      @easy_money_periodical_entity_item.easy_money_periodical_entity.project.recalculate_easy_money_periodical_entity_computed_values(@easy_money_periodical_entity_item.period_date)

      respond_to do |format|
        format.js {
          if params[:continue]
            create_new_easy_money_periodical_entity_item
            render :action => 'new'
          else
            render :partial => 'common/easy_redirect', :locals => {:back_url => params[:back_url] || easy_money_periodical_entity_path(@easy_money_periodical_entity)}
          end
        }
      end
    else
      respond_to do |format|
        format.js { render :action => 'new' }
      end
    end
  end

  def edit
    @easy_money_periodical_entity_item.safe_attributes = params[:easy_money_periodical_entity_item]

    respond_to do |format|
      format.js
    end
  end

  def update
    @easy_money_periodical_entity_item.safe_attributes = params[:easy_money_periodical_entity_item]

    if @easy_money_periodical_entity_item.save
      @easy_money_periodical_entity_item.easy_money_periodical_entity.project.recalculate_easy_money_periodical_entity_computed_values(@easy_money_periodical_entity_item.period_date)

      respond_to do |format|
        format.js {
          if params[:continue]
            create_new_easy_money_periodical_entity_item
            render :action => 'new'
          else
            render :partial => 'common/easy_redirect', :locals => {:back_url => params[:back_url] || easy_money_periodical_entity_path(@easy_money_periodical_entity)}
          end
        }
      end
    else
      respond_to do |format|
        format.js { render :action => 'edit' }
      end
    end
  end

  def destroy
    @easy_money_periodical_entity_item.destroy

    @easy_money_periodical_entity_item.easy_money_periodical_entity.project.recalculate_easy_money_periodical_entity_computed_values(@easy_money_periodical_entity_item.period_date)

    redirect_back_or_default easy_money_periodical_entity_path(@easy_money_periodical_entity)
  end

  private

  def find_easy_money_periodical_entity
    @easy_money_periodical_entity = EasyMoneyPeriodicalEntity.find(params[:easy_money_periodical_entity_id])
    @project = @easy_money_periodical_entity.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_easy_money_periodical_entity_item
    @easy_money_periodical_entity_item = EasyMoneyPeriodicalEntityItem.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def create_new_easy_money_periodical_entity_item
    @easy_money_periodical_entity_item = @easy_money_periodical_entity.easy_money_periodical_entity_items.build
    @easy_money_periodical_entity_item.safe_attributes = params[:easy_money_periodical_entity_item]
    @easy_money_periodical_entity_item.author ||= User.current
  end

end
