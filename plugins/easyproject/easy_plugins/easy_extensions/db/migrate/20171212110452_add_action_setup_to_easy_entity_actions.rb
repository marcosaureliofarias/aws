class AddActionSetupToEasyEntityActions < ActiveRecord::Migration[4.2]
  def change
    change_table :easy_entity_actions do |t|
      t.text :setup_actions, length: 25.megabytes, null: true
    end
  end
end
