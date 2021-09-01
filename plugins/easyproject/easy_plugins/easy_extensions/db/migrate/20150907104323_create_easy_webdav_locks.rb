class CreateEasyWebdavLocks < ActiveRecord::Migration[4.2]
  def change
    create_table :easy_webdav_locks do |t|
      t.integer :user_id
      t.string :scope, limit: 10
      t.string :type, limit: 10
      t.string :owner, limit: 50
      t.string :token
      t.string :path

      t.datetime :expired_at
    end
  end
end
