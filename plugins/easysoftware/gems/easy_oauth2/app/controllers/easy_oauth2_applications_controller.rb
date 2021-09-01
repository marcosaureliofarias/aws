class EasyOauth2ApplicationsController < Easy::Redmine::BasicController

  self.entity_class       = EasyOauth2Application
  self.entity_query_class = EasyOauth2ApplicationQuery
  self.allow_custom_type  = true

  before_action -> { find_entity }, only: %i[authorization]
  before_action -> { find_entity_by_guid }, only: %i[login]
  before_action :authorize_global, except: [:login]

  def authorization
    redirect_to @entity.oauth2_authorization_path
  end

  def login
    redirect_to @entity.oauth2_login_path
  end

  private

  def find_entity_by_guid
    @entity = EasyOauth2ClientApplication.find_by(guid: params[:guid])

    if @entity
      @parent_entity        = @entity.parent_entity
      @runtime_entity_class = @entity.class
    else
      render_404
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
