class ChangeProjectAuthor < ActiveRecord::Migration[4.2]
  def self.up
    author = User.active.where(:admin => true).first

    if author
      Project.where('author_id IS NULL').update_all(author_id: author.id)
    end
  end

  def self.down
  end
end
