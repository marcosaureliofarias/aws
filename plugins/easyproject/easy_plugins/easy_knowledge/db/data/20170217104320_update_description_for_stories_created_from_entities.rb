class UpdateDescriptionForStoriesCreatedFromEntities < EasyExtensions::EasyDataMigration

  include Redmine::I18n

  def up
    EasyKnowledgeStory.preload(:entity).where.not(entity_type: nil).each do |story|
      next unless story.description.blank?
      next unless story.entity
      case story.entity_type
      when 'Issue'
        description = story.entity.description.to_s
        journals = story.entity.journals.with_notes.order(:created_on)
        description << '<hr />' if journals.any?
        journals.each do |journal|
          description << "<strong>#{journal.user}</strong> #{format_time(journal.created_on).html_safe}"
          description << "#{journal.notes}"
        end
      when 'Journal'
        description = story.entity.notes
      end

      story.update_column(:description, description) if description
    end
  end

  def down

  end
end
