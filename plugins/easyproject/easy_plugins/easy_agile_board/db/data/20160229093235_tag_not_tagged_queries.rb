class TagNotTaggedQueries < ActiveRecord::Migration[4.2]
  def up
    EasyAgileBoardQuery.where(:is_tagged => false).update_all(:is_tagged => true)
  end

  def down
  end
end
