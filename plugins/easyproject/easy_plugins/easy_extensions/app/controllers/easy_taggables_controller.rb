class EasyTaggablesController < ApplicationController

  before_action :require_login
  before_action :find_all_tags, :only => [:autocomplete]
  before_action :create_entity_class, :find_entity, :sanitize_tags, :only => [:save_entity]
  before_action :find_tag, :only => [:tag, :destroy]

  helper :easy_query
  include EasyQueryHelper
  helper :sort
  include SortHelper
  helper :custom_fields
  include CustomFieldsHelper
  helper :context_menus
  include ContextMenusHelper

  def index
    respond_to do |format|
      format.html
    end
  end

  def autocomplete
    render :json => @tags
  end

  def save_entity
    old_values              = @entity.tag_list
    @entity.safe_attributes = { 'tag_list' => params[:entity][:tag_list] } if params[:entity]

    if @entity.save
      if @entity.respond_to?(:init_journal)
        new_values     = @entity.tag_list
        added_values   = new_values - old_values
        removed_values = old_values - new_values

        journal = @entity.init_journal(User.current)
        journal.details << JournalDetail.new(property: 'tags', prop_key: 'tag_list', old_value: removed_values.to_json, value: added_values.to_json)
        journal.save
      end

      respond_to do |format|
        format.js
        format.json { render json: @entity.tag_list }
      end
    else
      respond_to do |format|
        format.js { render status: :unprocessable_entity, plain: "showFlashMessage('error', '#{@entity.errors.full_messages.join(',')}')" }
        format.json { render_api_errors(@entity.errors.full_messages) }
      end
    end
  end

  def tag
    respond_to do |format|
      format.html
    end
  end

  def destroy
    @tag.destroy

    redirect_back_or_default easy_tags_path
  end

  private

  def create_entity_class
    @entity_class = params[:klass].classify.constantize
  rescue
    render_404
  end

  def find_all_tags
    @tags = ActsAsTaggableOn::Tag.joins(:taggings).where(taggings: { context: 'tags' }).order('tags.name asc').distinct.pluck(:name)
    if params[:suggestions].is_a?(Array)
      @tags = (@tags + params[:suggestions].map(&:to_s)).uniq.sort
    end
  end

  def find_entity
    @entity = @entity_class.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_tag
    @tag = ActsAsTaggableOn::Tag.named(params[:tag_name]).first
    render_404 if @tag.nil?
  end

  def sanitize_tags
    params[:entity][:tag_list].each { |tag| tag.tr!('.', '-') } if params[:entity]
  end

end
