class MoveEasyContactCommentsToJournals < ActiveRecord::Migration[4.2]

  def up
    Comment.transaction do
      Comment.where(:commented_type => [EasyContact.name, EasyContactGroup.name]).to_a.each do |comment|
        Journal.create(:journalized_type => comment.commented_type, :journalized_id => comment.commented_id, :notes => comment.comments, :created_on => comment.created_on)
      end
      Comment.where(:commented_type => [EasyContact.name, EasyContactGroup.name]).delete_all
    end

    remove_column :easy_contacts, :comments_count
    remove_column :easy_contacts_groups, :comments_count
  end

  def down
    add_column :easy_contacts, :comments_count, :integer, :default => 0
    add_column :easy_contacts_groups, :comments_count, :integer, :default => 0
  end

end
