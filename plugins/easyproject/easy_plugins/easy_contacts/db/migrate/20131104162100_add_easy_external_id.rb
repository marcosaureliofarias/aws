class AddEasyExternalId < ActiveRecord::Migration[4.2]
  def up

    add_column :easy_contacts, :easy_external_id, :string, {:null => true, :limit => 255}

  end

  def down

    remove_column :easy_contacts, :easy_external_id

  end
end
