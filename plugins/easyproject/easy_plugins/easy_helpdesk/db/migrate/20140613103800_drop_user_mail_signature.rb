class DropUserMailSignature < ActiveRecord::Migration[4.2]

  def self.up
    drop_table :easy_helpdesk_mail_signatures
  end

  def self.down
  end
end