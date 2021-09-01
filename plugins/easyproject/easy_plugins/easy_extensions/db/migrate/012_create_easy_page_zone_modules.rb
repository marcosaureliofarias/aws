class CreateEasyPageZoneModules < ActiveRecord::Migration[5.2]

  def change
    create_table :easy_page_zone_modules, id: false do |t|
      t.primary_key :uuid, :string
      t.belongs_to :easy_pages, null: false
      t.belongs_to :easy_page_available_zones, null: false, index: { name: "idx_easy_page_zone_modules_available_zone_id" }
      t.belongs_to :easy_page_available_modules, null: false, index: { name: "idx_easy_page_zone_modules_available_module_uuid" }
      t.belongs_to :user, null: true, index: { name: "idx_easy_page_zone_modules_user_id" }
      t.belongs_to :entity, null: true, index: { name: "idx_easy_page_zone_modules_entity_id" }
      t.integer :position, null: true, default: 1
      t.text :settings, null: true
      t.belongs_to :tab, index: { name: "idx_easy_page_zone_modules_tab_id" }

      t.index [:easy_pages_id, :easy_page_available_zones_id, :user_id], name: 'idx_easy_page_zone_modules_1'
    end
  end

end
