EasyExtensions::EasyBackgroundService.add(:easy_instant_messages) do

  active_if do
    User.current.logged?
  end

  execution do
    { count: EasyInstantMessage.for_user(User.current).where(unread: true).count }
  end

end
