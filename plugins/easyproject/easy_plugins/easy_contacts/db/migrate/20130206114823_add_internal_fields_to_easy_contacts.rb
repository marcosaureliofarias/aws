class AddInternalFieldsToEasyContacts < ActiveRecord::Migration[4.2]

  def self.up
    change_table :easy_contacts do |t|
      t.string  :internal_name, :null => true
      t.boolean :non_deletable, :default => false
      t.boolean :non_editable, :default => false
    end
  end

  def self.down
    change_table :easy_contacts do |t|
      t.remove :internal_name, :non_editable, :non_deletable
    end
  end

end
