class AddSsoToUsers < ActiveRecord::Migration[4.2]
  def up
    if !column_exists?(:users, :sso_provider)
      add_column :users, :sso_provider, :string, null: true
      add_column :users, :sso_uuid, :string, null: true
      add_index :users, [:sso_provider, :sso_uuid], name: 'idx_u_sso'
    end
  end

  def down
    remove_column :users, :sso_provider
    remove_column :users, :sso_uuid
  end
end
