class EasyUserChannel < EasyChannel

  def subscribed
    User.current.set_online_status('online') unless User.current.anonymous?

    stream_for current_user
  end

  def unsubscribed
    User.current.set_online_status('offline') unless User.current.anonymous?
  end

  def away
    User.current.set_online_status('away') unless User.current.anonymous? || %w(dnd invisible).include?(User.current.easy_online_status)
  end

  def dnd
    User.current.set_online_status('dnd') unless User.current.anonymous?
  end

  def invisible
    User.current.set_online_status('invisible') unless User.current.anonymous?
  end

  def appear(data)
    #User.current.appear(on: data['appearing_on'])
    User.current.set_online_status('online') unless User.current.anonymous? || %w(dnd invisible).include?(User.current.easy_online_status)
  end

  def self.send_message(user, message)
    title = "Greetings from #{User.current.name}"

    payload                   = { modal: {}, notification: {} }
    payload[:modal][:title]   = title
    payload[:modal][:message] = message
    payload[:modal][:buttons] = [{ text: I18n.t(:button_close), class: 'button', click: 'close' }]

    payload[:notification][:title]   = title
    payload[:notification][:options] = { body: message }

    broadcast_to(user, payload)
  end

end
