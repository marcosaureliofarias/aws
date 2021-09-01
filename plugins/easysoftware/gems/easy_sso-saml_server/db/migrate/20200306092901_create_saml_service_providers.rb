class CreateSamlServiceProviders < ActiveRecord::Migration[5.2]
  def change

    create_table :easy_saml_service_providers, force: true do |t|
      t.string :identifier, null: false, limit: 255, index: true
      t.text :settings, null: true
      t.text :metadata, null: true

      t.timestamps null: false
    end

  end
end
