class CreateOauth < ActiveRecord::Migration[4.2]
  def up

    create_table :easy_oauth_clients, force: true do |t|
      t.string :name, null: false
      t.string :app_id, null: false, limit: 191
      t.string :app_secret, null: false

      t.timestamps null: false
    end
    add_index :easy_oauth_clients, [:app_id], unique: true

    create_table :easy_oauth_access_grants, force: true do |t|
      t.string :code, null: false
      t.string :access_token, null: false
      t.string :refresh_token, null: false
      t.datetime :access_token_expires_at
      t.references :user, null: false
      t.references :easy_oauth_client, null: false
      t.string :state

      t.timestamps null: false
    end

    create_table :easy_oauth_authentications, force: true do |t|
      t.references :user, null: false
      t.string :provider, null: false, limit: 191
      t.string :uuid, null: false, limit: 191

      t.timestamps null: false
    end
    add_index :easy_oauth_authentications, [:provider, :uuid], unique: true

  end

  def down
    drop_table :easy_oauth_authentications
    drop_table :easy_oauth_access_grants
    drop_table :easy_oauth_clients
  end
end
