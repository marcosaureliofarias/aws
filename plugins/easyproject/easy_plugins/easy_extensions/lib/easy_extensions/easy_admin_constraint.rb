class EasyAdminConstraint
  def matches?(request)
    user_id = request.session[:user_id]
    user_id.present? && User.find_by_id(user_id).try(:admin?)
  end
end
