class EasyCurrenciesController < ApplicationController
  layout 'admin'

  before_action :require_admin, except: :index
  before_action :find_easy_currency, :only => [:edit, :update, :destroy]

  accept_api_auth :index

  helper :sort
  include SortHelper

  def index
    @easy_currencies     = EasyCurrency.all
    @limit               = per_page_option
    @limit_hit           = EasyCurrency.all.count >= EasyCurrency::ACTIVATED_CURRENCY_LIMIT
    @easy_currency_pages = Redmine::Pagination::Paginator.new @easy_currencies.count, @limit, params['page']
    @offset              ||= @easy_currency_pages.offset

    respond_to do |format|
      format.html
      format.api
    end
  end

  def new
    @projects                      = Project.where.not(:status => Project::STATUS_ARCHIVED)
    @easy_currency                 = EasyCurrency.new
    @easy_currency.safe_attributes = params[:easy_currency]

    respond_to do |format|
      format.html
    end
  end

  def create
    @easy_currency                 = EasyCurrency.new
    @easy_currency.safe_attributes = params[:easy_currency]

    if @easy_currency.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_create)
          redirect_back_or_default(:action => 'index')
        }
      end
    else
      respond_to do |format|
        @projects = Project.where.not(:status => Project::STATUS_ARCHIVED)
        format.html { render :action => 'new' }
      end
    end
  end

  def edit
    @projects = Project.where.not(:status => Project::STATUS_ARCHIVED)
    respond_to do |format|
      format.html
    end
  end

  def update
    @easy_currency.safe_attributes = params[:easy_currency]

    if @easy_currency.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_back_or_default(:action => 'index')
        }
      end
    else
      respond_to do |format|
        @projects = Project.where.not(:status => Project::STATUS_ARCHIVED)
        format.html { render :action => 'edit' }
      end
    end
  end

  def destroy
    @easy_currency.destroy

    redirect_back_or_default(:action => 'index')
  end

  private

  def find_easy_currency
    @easy_currency = EasyCurrency.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
