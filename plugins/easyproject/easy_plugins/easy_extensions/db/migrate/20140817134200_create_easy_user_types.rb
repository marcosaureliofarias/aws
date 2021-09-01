class CreateEasyUserTypes < ActiveRecord::Migration[4.2]

  def up
    create_table :easy_user_types do |t|
      t.string :name, :null => false
      t.integer :position, :default => 1
      t.boolean :is_default, :default => false, :null => false
      t.boolean :internal, :default => true, :null => false

      t.text :settings, :limit => 999.megabytes

      t.timestamps
    end
  end

  def down
    drop_table :easy_user_types
  end

end
