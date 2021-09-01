class CreateUserMailSignature < ActiveRecord::Migration[4.2]

  def self.up
    add_column :users, :easy_mail_signature, :text, { :null => true }
  end

  def self.down
    remove_column :users, :easy_mail_signature
  end
end
