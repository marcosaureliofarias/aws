class ChangeExtSyncEntity < ActiveRecord::Migration[4.2]
  def self.up
    adapter_name = EasyExternalSynchronisation.connection_config[:adapter]
    case adapter_name.downcase
    when 'postgresql'
      change_column :easy_external_synchronisations, :entity_id, 'integer USING CAST(entity_id AS integer)', { :null => true }
    else
      change_column :easy_external_synchronisations, :entity_id, :integer, { :null => true }
    end
    change_column :easy_external_synchronisations, :entity_type, :string, { :null => true, :limit => 255 }
  end

  def self.down
    change_column :easy_external_synchronisations, :entity_id, :string, { :null => true }
    change_column :easy_external_synchronisations, :entity_type, :string, { :null => true, :limit => 2048 }
  end
end
