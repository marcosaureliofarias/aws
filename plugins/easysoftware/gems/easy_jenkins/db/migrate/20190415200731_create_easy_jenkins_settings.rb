class CreateEasyJenkinsSettings < ActiveRecord::Migration[5.2]
  def change
    create_table :easy_jenkins_settings do |t|
      t.string :url
      t.string :user_token
      t.string :user_name
      t.timestamps
    end
  end
end
