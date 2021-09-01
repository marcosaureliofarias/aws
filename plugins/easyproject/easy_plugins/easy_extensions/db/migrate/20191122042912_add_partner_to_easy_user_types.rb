class AddPartnerToEasyUserTypes < ActiveRecord::Migration[4.2]
  def up
    add_column :easy_user_types, :partner, :boolean, { null: false, default: false, index: true }
  end

  def down
    remove_column :easy_user_types, :partner
  end
end
