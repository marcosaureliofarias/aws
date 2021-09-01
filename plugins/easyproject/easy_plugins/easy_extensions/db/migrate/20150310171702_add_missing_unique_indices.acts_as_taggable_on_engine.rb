# This migration comes from acts_as_taggable_on_engine (originally 2)
class AddMissingUniqueIndices < ActiveRecord::Migration[4.2]
  def self.up
    # Unique hack
    ActsAsTaggableOn::Tag.all.group(:name).count.select { |c, v| v > 1 }.each do |name, c|
      tag = ActsAsTaggableOn::Tag.where(:name => name).last.destroy
      ActsAsTaggableOn::Tagging.where(:tag_id => tag.id).delete_all
    end
    add_index(:tags, :name, unique: true) unless index_exists?(:tags, :name, unique: true)

    remove_index :taggings, :tag_id
    remove_index :taggings, [:taggable_id, :taggable_type, :context]
    add_index :taggings,
              [:tag_id, :taggable_id, :taggable_type, :context, :tagger_id, :tagger_type],
              unique: true, name: 'taggings_idx'
  end

  def self.down
    remove_index :tags, :name

    remove_index :taggings, name: 'taggings_idx'
    add_index :taggings, :tag_id
    add_index :taggings, [:taggable_id, :taggable_type, :context]
  end
end
