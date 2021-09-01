class EasyDummyChannel < EasyChannel

  def subscribed
    if params[:status]
      stream_from "easy_dummy_channel_#{params[:status]}"
    else
      stream_from "easy_dummy_channel"
    end
  end

  def unsubscribed
  end

end
