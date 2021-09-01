class MigrateEasyFavoritesKnowledge < EasyExtensions::EasyDataMigration
  def up
    return unless column_exists?(:easy_knowledge_assigned_stories, :is_favorite)

    assigned_stories = EasyKnowledgeAssignedStory.where(is_favorite: true).where(entity_type: 'Principal')

    EasyFavorite.transaction do
      assigned_stories.find_each(batch_size: 50) do |assigned_story|
        EasyFavorite.create!(entity: assigned_story, user: assigned_story.entity)
      end
    end

    remove_column :easy_knowledge_assigned_stories, :is_favorite
    EasyKnowledgeAssignedStory.reset_column_information
  end

  def self.down
  end
end