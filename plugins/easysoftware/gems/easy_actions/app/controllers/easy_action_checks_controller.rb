class EasyActionChecksController < Easy::Redmine::BasicController

  menu_item :easy_action

  self.entity_class       = EasyActionCheck
  self.entity_query_class = EasyActionCheckQuery

  before_action -> { find_entity }, only: %i[passed failed]
  before_action :authorize_global

  accept_api_auth :passed, :failed

  def passed
    @entity.update(status: :ok, result: params[:result])

    respond_to do |format|
      format.api { render_api_ok }
    end
  end

  def failed
    @entity.update(status: :failed, result: params[:result])

    respond_to do |format|
      format.api { render_api_ok }
    end
  end

end
