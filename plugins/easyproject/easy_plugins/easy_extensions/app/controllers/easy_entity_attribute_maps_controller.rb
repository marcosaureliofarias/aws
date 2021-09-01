class EasyEntityAttributeMapsController < ApplicationController
  before_action :require_login
  before_action :find_project_by_project_id, :if => lambda { params[:project_id].present? }

  # Display form with current mapped fields
  # for A entity => to entity B
  def index
    # pass params from `map` action
    @easy_entity_attribute_maps = EasyEntityAttributeMap.where(:entity_from_type => params[:entity_from], :entity_to_type => params[:entity_to])
    if @easy_entity_attribute_maps.empty? && (params[:entity_from].present? && params[:entity_to].present?)
      @easy_entity_attribute_maps = guess_entity_attribute_maps(params[:entity_from], params[:entity_to])
    end

    @entity_from_name = l("label_#{params[:entity_from].underscore.tr('/', '_')}", :default => h(params[:entity_from])) if params[:entity_from].present?
    @entity_to_name   = l("label_#{params[:entity_to].underscore.tr('/', '_')}", :default => h(params[:entity_to])) if params[:entity_to].present?

    respond_to do |format|
      format.html { render('index') }
      format.js { render('index') }
    end
  end

  # render 1 single row of form
  # single entity attribute => to entity B attribute
  def new
    @easy_entity_attribute_map                 = EasyEntityAttributeMap.new(:entity_from_type => params[:entity_from], :entity_to_type => params[:entity_to])
    @easy_entity_attribute_map.safe_attributes = params[:easy_entity_attribute_map]

    respond_to do |format|
      format.html
      format.js
    end
  end

  # Create row
  def create
    @easy_entity_attribute_map                 = EasyEntityAttributeMap.new(:entity_from_type => params[:entity_from], :entity_to_type => params[:entity_to])
    @easy_entity_attribute_map.safe_attributes = params[:easy_entity_attribute_map]

    respond_to do |format|
      if @easy_entity_attribute_map.save
        if params[:continue].present?
          @easy_entity_attribute_map = @easy_entity_attribute_map.dup
          @continue                  = true
        end
        format.html do
          flash[:notice] = l(:notice_successful_create)
          @continue ? render({ :action => 'new' }) : redirect({ :action => 'index' }) # continue with add another row or redirect to form
        end
        format.js # append create row to form table. Show another form row if continue
      else
        format.html { render({ :action => 'new' }) }
        format.js
      end
    end
  end

  def destroy
    @easy_entity_attribute_map = EasyEntityAttributeMap.find(params[:id])
    @easy_entity_attribute_map.destroy
    respond_to do |format|
      format.html do
        flash[:notice] = l(:notice_successful_delete)
        redirect_to({ :action => 'index', :entity_from => @easy_entity_attribute_map.entity_from_type, :entity_to => @easy_entity_attribute_map.entity_to_type })
      end
      format.js
    end
  end

  # ====================

  private

  def guess_entity_attribute_maps(entity_from, entity_to)
    from, to     = entity_from.constantize, entity_to.constantize
    from_columns = from.associated_query_class && from.associated_query_class.new.available_columns || []
    to_columns   = to.associated_query_class && to.associated_query_class.new.available_columns || []
    maps         = []
    (from_columns.map(&:name) & to_columns.map(&:name)).each do |guessed|
      maps << EasyEntityAttributeMap.create(:entity_from_type => from, :entity_to_type => to, :entity_from_attribute => guessed, :entity_to_attribute => guessed)
    end
    maps
  end

end
