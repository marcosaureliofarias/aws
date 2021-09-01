class FixLimitOnReferrer < ActiveRecord::Migration[5.2]
  def up
    change_column :easy_oauth2_access_grants, :referrer, :string, limit: 2048
  end
end
