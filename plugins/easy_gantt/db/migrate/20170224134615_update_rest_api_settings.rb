class UpdateRestApiSettings < ActiveRecord::Migration[4.2]

  def up
    Setting.where(name: 'rest_api_enabled').update_all(value: '1')
  end

  def down
  end

end
