class CreateEasyTwofaRemembers < ActiveRecord::Migration[5.2]
  def up
    create_table :easy_twofa_remembers do |t|
      t.integer :easy_twofa_user_scheme_id, null: false, index: true
      t.date :expired_at, null: false
      t.text :device, null: false

      t.timestamps null: false
    end
  end

  def down
    drop_table :easy_twofa_remembers
  end
end
