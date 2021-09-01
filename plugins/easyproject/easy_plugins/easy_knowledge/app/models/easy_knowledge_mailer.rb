class EasyKnowledgeMailer < Mailer

  def self.deliver_recommended_stories(stories, recipients)
    return if User.current.pref.no_notification_ever

    users = valid_recipients(recipients)
    proposer = User.current
    users.each do |user|
      recommended_stories(user, stories, proposer).deliver_later
    end
  end

  def recommended_stories(user, stories, proposer)
    @proposer = proposer
    @stories = stories

    mail to: user, subject: l(:label_easy_knowledge)
  end

  def self.deliver_recommended_story_updated(story)
    return if story.author && story.author.pref.no_notification_ever

    users = valid_recipients(story.notified_updated_users)
    users.each do |user|
      recommended_story_updated(user, story).deliver_later
    end
  end

  def recommended_story_updated(user, story)
    @story = story
    @story_url = easy_knowledge_story_url(story)

    mail to: user, subject: l(:label_easy_knowledge)
  end

  def self.deliver_easy_knowledge_story_added(story)
    return if story.author && story.author.pref.no_notification_ever

    users = story.recipients
    users.each do |user|
      easy_knowledge_story_added(user, story).deliver_later
    end
  end

  def easy_knowledge_story_added(user, story)
    @story = story
    @story_url = easy_knowledge_story_url(story)

    mail to: user, subject: l(:label_easy_knowledge)
  end

  def self.valid_recipients(users)
    if users.first.class == 'User'
      users.reject{|r| r.mail_notification == 'none'}
    else
      users
    end
  end

end
