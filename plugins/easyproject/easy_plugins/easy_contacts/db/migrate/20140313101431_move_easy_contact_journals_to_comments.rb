class MoveEasyContactJournalsToComments < ActiveRecord::Migration[4.2]
  def up
    add_column :easy_contacts, :comments_count, :integer, :default => 0
    add_column :easy_contacts_groups, :comments_count, :integer, :default => 0

    Journal.transaction do
      Journal.where(:journalized_type => ['EasyContact', 'EasyContactGroup']).all.each do |journal|
        Comment.create(:commented_type => journal.journalized_type, :commented_id => journal.journalized_id, :author_id => journal.user_id, :comments => journal.notes, :created_on => journal.created_on)
      end
      # EasyContacts haven't any JournalDetail
      Journal.where(:journalized_type => ['EasyContact', 'EasyContactGroup']).delete_all
    end
  end

  def down
    remove_column :easy_contacts, :comments_count
    remove_column :easy_contacts_groups, :comments_count
  end
end
