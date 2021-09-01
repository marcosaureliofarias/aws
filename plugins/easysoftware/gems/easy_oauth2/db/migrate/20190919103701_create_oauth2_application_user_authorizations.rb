class CreateOauth2ApplicationUserAuthorizations < ActiveRecord::Migration[5.2]
  def change
    create_table :easy_oauth2_application_user_authorizations, force: true do |t|
      t.belongs_to :easy_oauth2_application, null: false, index: { name: 'idx_eoaua_1' }
      t.belongs_to :user, null: false, index: { name: 'idx_eoaua_2' }

      t.string :code, null: false
      t.string :browser, null: true

      t.timestamps null: false

      t.index [:easy_oauth2_application_id, :user_id], name: 'idx_eoaua_3'
    end
  end
end
