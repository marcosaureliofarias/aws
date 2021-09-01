class EasyWatchersListAutocompleteController < ApplicationController

  def assignable_watchers
    @selected_watcher_ids = Array.wrap(params[:selected_watcher_ids])
    if params[:entity_klass] && (entity_klass = params[:entity_klass].camelcase.safe_constantize)
      @entity = entity_klass.new
      @entity.project_id = params[:project_id] if params[:project_id] && @entity.respond_to?(:project_id)
    end
    @users, @groups = @entity.addable_watcher_users, @entity.available_groups

    if params[:filter_string].present?
      @groups = @groups.select { |group| assignable_entity?(group) }
      @users = @users.select { |user| assignable_entity?(user) }
    else
      @groups = @groups.select { |group| !@selected_watcher_ids.include?(group.id.to_s) }.first(EasyWatchersListAutocomplete.setting(:watchers_groups_limit).to_i)
      @users = @users.select { |user| !@selected_watcher_ids.include?(user.id.to_s) }.first(EasyWatchersListAutocomplete.setting(:watchers_users_limit).to_i)
    end

    respond_to do |format|
      format.js
    end
  end

  private

  def assignable_entity?(entity)
    entity.name.downcase.include?(params[:filter_string].downcase) && !@selected_watcher_ids.include?(entity.id.to_s)
  end

end
