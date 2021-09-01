class EasyKnowledgeBaseController < ApplicationController

  helper :easy_knowledge
  include EasyKnowledgeHelper
  helper :easy_knowledge_categories
  include EasyKnowledgeCategoriesHelper
  helper :easy_knowledge_stories
  include EasyKnowledgeStoriesHelper
  helper :easy_query
  include EasyQueryHelper
  helper :sort
  include SortHelper

  before_action :easy_knowledge_authorize_view_easy_knowledge_permission

private

  def cache_permissions
    user = User.current
    @can = {
        view_easy_knowledge: user.allowed_to_globally?(:view_easy_knowledge),
        read_global_stories: user.allowed_to_globally?(:read_global_stories),
        manage_own_personal_categories: user.allowed_to_globally?(:manage_own_personal_categories),
        create_global_stories: user.allowed_to_globally?(:create_global_stories),
        edit_own_global_stories: user.allowed_to_globally?(:edit_own_global_stories),
        edit_all_global_stories: user.allowed_to_globally?(:edit_all_global_stories),
        manage_global_categories: user.allowed_to_globally?(:manage_global_categories),
        stories_assignment: user.allowed_to_globally?(:stories_assignment),

        read_project_stories: user.allowed_to?(:read_project_stories, @project),
        edit_all_project_stories: user.allowed_to?(:edit_all_project_stories, @project),
        edit_own_project_stories: user.allowed_to?(:edit_own_project_stories, @project),
        create_project_stories: user.allowed_to?(:create_project_stories, @project),
        manage_project_categories: user.allowed_to?(:manage_project_categories, @project),
    }
  end

  def easy_knowledge_authorize_stories_editable
    deny_access unless easy_knowledge_stories_editable?
  end

  def easy_knowledge_authorize_story_visible
    deny_access if @story && !@story.visible?
  end

  def easy_knowledge_authorize_create_permission
    deny_access unless @project ? @can[:create_project_stories] : @can[:create_global_stories]
  end

  def easy_knowledge_authorize_view_easy_knowledge_permission
    if @can
      deny_access unless @can[:view_easy_knowledge]
    else
      deny_access unless User.current.allowed_to_globally?(:view_easy_knowledge)
    end
  end

  def easy_knowledge_authorize_stories_assignment_permission
    deny_access unless @can[:stories_assignment]
  end

  def easy_knowledge_action_permissions
    deny_access unless User.current.allowed_to_globally?({:controller => params[:controller], :action => params[:action]}, {})
  end

  def find_story
    @story = EasyKnowledgeStory.find(params[:id])
  rescue
    render_404
  end

  def find_project
    @project = Project.find(params[:project_id]) unless params[:project_id].blank?
  rescue
    render_404
  end

  def find_stories
    @easy_knowledge_stories = EasyKnowledgeStory.where(:id => params[:id] || params[:ids]).to_a
  end
end
