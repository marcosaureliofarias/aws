class CreateOauth2Tables < ActiveRecord::Migration[5.2]
  def change
    create_table :easy_oauth2_applications, force: true do |t|
      t.string :guid, null: false, limit: 36, index: { unique: true }
      t.string :type, null: false, index: true

      t.string :name, null: false
      t.boolean :active, null: false, default: true

      t.string :app_id, index: { unique: true }
      t.string :app_secret
      t.string :app_url

      t.text :settings, null: true

      t.timestamps null: false
    end

    add_index :easy_oauth2_applications, [:app_id, :app_secret], name: 'idx_eop_1', unique: true

    create_table :easy_oauth2_application_callbacks, force: true do |t|
      t.belongs_to :easy_oauth2_application, null: false, index: { name: 'idx_eoac_1' }

      t.string :url, null: false

      t.timestamps null: false
    end

    create_table :easy_oauth2_access_grants, force: true do |t|
      t.belongs_to :easy_oauth2_application, null: false
      t.belongs_to :user, null: false
      t.string :code
      t.string :access_token
      t.string :refresh_token
      t.datetime :access_token_expires_at
      t.string :state
      t.string :referrer, limit: 2048

      t.timestamps null: false
    end

    add_index :easy_oauth2_access_grants, [:easy_oauth2_application_id, :code], name: 'idx_eoag_1'

    create_table :easy_oauth2_authentications, force: true do |t|
      t.belongs_to :user, null: false
      t.string :provider
      t.string :uid
      t.text :provider_data

      t.timestamps null: false
    end

    add_index :easy_oauth2_authentications, [:provider, :uid], name: 'idx_eoa_1', unique: true

    create_table :easy_oauth2_tokens, force: true do |t|
      t.belongs_to :entity, polymorphic: true, index: true

      t.string :key, null: false
      t.string :value, null: false
      t.datetime :valid_until, null: true, index: true

      t.timestamps null: false
    end

  end
end
