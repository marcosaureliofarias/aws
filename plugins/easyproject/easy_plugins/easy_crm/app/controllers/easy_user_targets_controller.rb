class EasyUserTargetsController < ApplicationController

  before_action :authorize_global
  before_action :find_user, only: [:remove_user]

  helper :easy_crm
  helper :easy_setting
  include EasySettingHelper
  helper :easy_crm_settings

  include_query_helpers

  def index
    index_for_easy_query(EasyUserTargetQuery)
  end

  def bulk_edit
    @easy_user_target_pages, @users = paginate(User.where(has_target: true).sorted, per_page: per_page_option)
  end

  def bulk_update
    if params[:user_targets].present?
      unsaved_target = []
      params[:user_targets].each do |user_id, targets|
        targets.each do |target|
          @quarter ||= target[:valid_from]
          next if target[:target].blank?

          if target[:easy_user_target_id].blank?
            easy_user_target = EasyUserTarget.new
            easy_user_target.safe_attributes = target
            easy_user_target.user_id = user_id
            easy_user_target.currency = EasySetting.value('user_target_currency')
            unsaved_target << easy_user_target unless easy_user_target.save
          else
            find_target(target[:easy_user_target_id])
            unsaved_target << @user_target unless @user_target.update_attributes(target: target[:target])
          end
        end
      end
    end
    respond_to do |format|
      if unsaved_target.blank?
        format.html do
          flash[:notice] = l(:notice_successful_update)
          redirect_back_or_default(bulk_edit_easy_user_targets_path(date: @quarter))
        end
      else
        messages = []
        unsaved_target.each do |target|
          messages << "#{ target.user }: #{ target.errors.full_messages.flatten.join(', ') }"
        end
        format.html do
          flash[:error] = messages.join(', ')
          redirect_back_or_default(bulk_edit_easy_user_targets_path(date: @quarter))
        end
      end
    end
  end

  def remove_user
    respond_to do |format|
      if @user.update_attribute(:has_target, false)
        format.js
      else
        format.api { render_validation_errors(@user) }
      end
    end
  end

  def add_user
    respond_to do |format|
      if !params[:entity_id].blank? || !params[:user_ids].blank?
        scope = case params[:entity]
                  when 'easy_user_type'
                    User.where(easy_user_type_id: params[:entity_id], status: User::STATUS_ACTIVE).where(has_target: false)
                  when 'group'
                    User.joins(:groups).where(has_target: false).where(users_groups_users_join: {group_id: params[:entity_id]})
                  else
                    User.where(id: params[:user_ids])
                end

        scope.update_all(has_target: true)

        format.html do
          flash[:notice] = l(:notice_successful_update)
          redirect_back_or_default(bulk_edit_easy_user_targets_path)
        end
      else
        @entity_type = params[:entity]
        format.html
        format.js
      end
    end
  end

  def set_user_target_currency
    EasyUserTarget.update_all(currency: params[:easy_setting][:user_target_currency]) if !params[:easy_setting].blank?
    save_easy_settings
    respond_to do |format|
      format.api { render_api_ok }
    end
  end

  private

  def find_target(id = nil)
    @user_target = EasyUserTarget.find(params[:id] || id)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_user
    @user = User.find(params[:user_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
