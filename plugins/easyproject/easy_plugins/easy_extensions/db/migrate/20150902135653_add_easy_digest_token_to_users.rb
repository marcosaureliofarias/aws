class AddEasyDigestTokenToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :easy_digest_token, :string
  end
end
