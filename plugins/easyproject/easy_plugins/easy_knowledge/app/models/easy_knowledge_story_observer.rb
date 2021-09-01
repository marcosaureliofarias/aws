class EasyKnowledgeStoryObserver < ActiveRecord::Observer

  observe :easy_knowledge_story

  def after_create(story)
    EasyKnowledgeMailer.easy_knowledge_story_added(story).deliver if Setting.notified_events.include?('easy_knowledge_story_added')
  end

  def after_update(story)
    if Setting.notified_events.include?('easy_knowledge_story_updated')
      users = User.active.sorted.where(id: story.user_ids | story.user_read_records.map(&:user_id)).to_a
      EasyKnowledgeMailer.recommended_story_updated(story, users).deliver if users.any?
    end
  end

end
