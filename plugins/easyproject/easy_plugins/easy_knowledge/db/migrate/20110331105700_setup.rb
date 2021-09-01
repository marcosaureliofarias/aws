class Setup < ActiveRecord::Migration[5.2]
  def change

    create_table :easy_knowledge_categories do |t|
      t.column :name, :string, null: false
      t.column :author_id, :integer, null: false
      t.column :entity_type, :string, null: true
      t.column :entity_id, :integer, null: true
      t.column :parent_id, :integer, null: true
      t.column :lft, :integer, null: true
      t.column :rgt, :integer, null: true
      t.column :created_on, :timestamp
      t.column :updated_on, :timestamp
    end

    create_table :easy_knowledge_stories do |t|
      t.column :name, :string, null: false
      t.column :author_id, :integer, null: false
      t.column :entity_type, :string, null: false
      t.column :entity_id, :integer, null: false
      t.column :storyviews, :integer, null: false, default: 0
      t.column :created_on, :timestamp
      t.column :updated_on, :timestamp
      t.column :version, :integer, null: false
    end

    create_table :easy_knowledge_assigned_stories do |t|
      t.column :story_id, :integer, null: false
      t.column :author_id, :integer, null: false
      t.column :entity_type, :string, null: false
      t.column :entity_id, :integer, null: false
      t.column :created_on, :timestamp
      t.column :updated_on, :timestamp
    end

    create_table :easy_knowledge_story_categories, primary_key: %i[story_id category_id] do |t|
      t.belongs_to :story
      t.belongs_to :category
    end

    create_table :easy_knowledge_story_references, primary_key: %i[referenced_by referenced_to] do |t|
      t.integer :referenced_by, null: false, index: { name: "idx_easy_knowledge_story_references_by" }
      t.integer :referenced_to, null: false, index: { name: "idx_easy_knowledge_story_references_to" }
    end

  end

end
