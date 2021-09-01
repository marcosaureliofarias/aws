class AddEasySynchronizationsSource < ActiveRecord::Migration[4.2]

  def self.up
    add_column :easy_external_synchronisations, :external_source, :string, { :null => true, :limit => 2048 }
  end

  def self.down
  end
end