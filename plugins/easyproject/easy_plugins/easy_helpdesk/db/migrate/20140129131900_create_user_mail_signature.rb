class CreateUserMailSignature < ActiveRecord::Migration[4.2]

  def self.up
    create_table :easy_helpdesk_mail_signatures do |t|
      t.column :user_id, :integer, {:null => false}
      t.column :signature_name, :string, {:null => false, :limit => 255}
      t.column :signature, :text, {:null => false}
    end
  end

  def self.down
  end
end