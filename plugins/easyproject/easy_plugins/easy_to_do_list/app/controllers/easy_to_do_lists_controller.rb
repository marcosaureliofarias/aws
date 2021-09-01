class EasyToDoListsController < ApplicationController

  accept_api_auth [:index, :show, :update, :destroy, :create]

  before_action :authorize_global
  before_action :find_easy_to_do_list, only: [:update, :destroy, :show]
  before_action :authorize_current_user, only: [:update, :destroy, :show]

  def show_toolbar
    if User.current.easy_to_do_lists.empty?
      User.current.easy_to_do_lists.create(name: l(:heading_easy_to_do_list))
    end

    @easy_to_do_lists = User.current.easy_to_do_lists.sorted.preload(easy_to_do_list_items: :entity)
    @new_easy_to_do_list = EasyToDoList.new if Setting.plugin_easy_to_do_list['enable_more_to_do_lists'] == '1'
    respond_to do |format|
      format.js
    end
  end

  def index
    @easy_to_do_lists = User.current.easy_to_do_lists.sorted.preload(easy_to_do_list_items: :entity)
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
    @easy_to_do_list = User.current.easy_to_do_lists.build
    @easy_to_do_list.safe_attributes = params[:easy_to_do_list] if params[:easy_to_do_list]
    @easy_to_do_list.position ||= 1

    if @easy_to_do_list.save
      respond_to do |format|
        if params[:html]
          format.api { render action: 'refresh' }
        else
          format.api { render action: 'show', status: :created, location: easy_to_do_list_url(@easy_to_do_list) }
        end
      end
    else
      respond_to do |format|
        format.api { render_validation_errors @easy_to_do_list }
      end
    end
  end

  def update
    @easy_to_do_list.safe_attributes = params[:easy_to_do_list] if params[:easy_to_do_list]

    if @easy_to_do_list.save
      respond_to do |format|
        if params[:html]
          format.api { render action: 'refresh' }
        else
          format.api { render_api_ok }
        end
      end
    else
      respond_to do |format|
        format.api { render_validation_errors @easy_to_do_list }
      end
    end
  end

  def destroy
    @easy_to_do_list.destroy

    respond_to do |format|
      format.api { render_api_ok }
    end
  end

  private

  def find_easy_to_do_list
    @easy_to_do_list = EasyToDoList.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def authorize_current_user
    render_403 if @easy_to_do_list.user_id != User.current.id
  end

end
