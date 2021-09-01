class AddAllowExteralToShortUrl < ActiveRecord::Migration[4.2]
  def up
    add_column :easy_short_urls, :allow_external, :boolean, { default: false, null: false }
  end

  def down
    remove_column :easy_short_urls, :allow_external
  end
end
