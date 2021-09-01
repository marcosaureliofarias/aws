# encoding: utf-8
module EasyKnowledgeBase

  def self.toolbar_enabled?
    User.current.allowed_to_globally?(:view_easy_knowledge)
  end

end
