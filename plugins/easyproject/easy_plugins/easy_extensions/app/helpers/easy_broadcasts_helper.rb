module EasyBroadcastsHelper

  def render_api_easy_broadcast(api, easy_broadcast)
    api.easy_broadcast do
      api.id easy_broadcast.id
      api.message easy_broadcast.message
      api.start_at easy_broadcast.start_at
      api.end_at easy_broadcast.end_at
      api.created_at easy_broadcast.created_at
      api.updated_at easy_broadcast.updated_at
    end
  end

end
