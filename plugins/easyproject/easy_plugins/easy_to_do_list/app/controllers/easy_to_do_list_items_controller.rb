class EasyToDoListItemsController < ApplicationController

  accept_api_auth :show, :create, :update, :destroy, :index

  before_action :authorize_global

  before_action :find_easy_to_do_list, only: [:create, :update, :destroy, :show, :index]
  before_action :find_easy_to_do_list_item, only: [:update, :destroy, :show]
  before_action :authorize_current_user, only: [:create, :update, :destroy, :show, :index]

  def index
    @easy_to_do_list_items = @easy_to_do_list.easy_to_do_list_items.sorted.to_a
    respond_to do |format|
      format.api
    end
  end

  def show
    respond_to do |format|
      format.api
    end
  end

  def create
    @easy_to_do_list_item = @easy_to_do_list.easy_to_do_list_items.build
    @easy_to_do_list_item.safe_attributes = params[:easy_to_do_list_item] if params[:easy_to_do_list_item]
    @easy_to_do_list_item.position ||= 1

    if @easy_to_do_list_item.save
      respond_to do |format|
        if params[:html]
          format.api { render action: 'refresh' }
        else
          format.api { render action: 'show', status: :created, location: easy_to_do_list_item_url(@easy_to_do_list_item) }
        end
      end
    else
      respond_to do |format|
        format.api { render_validation_errors @easy_to_do_list_item }
      end
    end
  end

  def update
    @easy_to_do_list_item.safe_attributes = params[:easy_to_do_list_item] if params[:easy_to_do_list_item]
    if @easy_to_do_list_item.save
      respond_to do |format|
        if params[:html]
          format.api { render action: 'refresh' }
        else
          format.api { render_api_ok }
        end
      end
    else
      respond_to do |format|
        format.api { render_validation_errors @easy_to_do_list_item }
      end
    end
  end

  def destroy
    @easy_to_do_list_item.destroy

    respond_to do |format|
      format.api { render_api_ok }
    end
  end

  private

  def find_easy_to_do_list
    @easy_to_do_list = EasyToDoList.find(params[:easy_to_do_list_id]) if params[:easy_to_do_list_id]
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_easy_to_do_list_item
    @easy_to_do_list_item = EasyToDoListItem.find(params[:id])
    @easy_to_do_list ||= @easy_to_do_list_item.easy_to_do_list
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def authorize_current_user
    render_403 if @easy_to_do_list.user_id != User.current.id
  end

end
