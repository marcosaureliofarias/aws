class ChangeMailboxes < ActiveRecord::Migration[4.2]

  def self.up
    EasyHelpdeskMailTemplate.all.each do |template|
      template.mailboxes.delete_all
    end
  end

  def self.down
  end
end