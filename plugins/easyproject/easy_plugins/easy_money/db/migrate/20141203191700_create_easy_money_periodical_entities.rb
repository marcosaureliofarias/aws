class CreateEasyMoneyPeriodicalEntities < ActiveRecord::Migration[4.2]
  def self.up

    create_table :easy_money_periodical_entities, :force => true do |t|

      t.column :type, :string, {:null => false, :limit => 255}
      t.column :name, :string, {:null => false, :limit => 255}
      t.column :column_idx, :integer, {:null => false, :default => 1}

      t.column :entity_type, :string, {:null => false, :limit => 255}
      t.column :entity_id, :integer, {:null => false}
      t.column :project_id, :integer, {:null => true}

      t.column :parent_id, :integer, { :null => true }
      t.column :position, :integer, { :null => true, :default => 1 }

    end
    add_index :easy_money_periodical_entities, [:type], :name => 'idx_empe_1'
    add_index :easy_money_periodical_entities, [:type, :entity_type, :entity_id], :name => 'idx_empe_2'
    add_index :easy_money_periodical_entities, [:type, :project_id], :name => 'idx_empe_3'

    create_table :easy_money_periodical_entity_items, :force => true do |t|

      t.column :easy_money_periodical_entity_id, :integer, {:null => false}
      t.column :author_id, :integer, {:null => false}
      t.column :period_date, :date, {:null => false}
      t.column :name, :string, {:null => true, :limit => 255}
      t.column :description, :text, {:null => true}
      t.column :price1, :decimal, {:null => false, :precision => 30, :scale => 2, :default => 0.0}
      t.column :price2, :decimal, {:null => false, :precision => 30, :scale => 2, :default => 0.0}
      t.column :vat, :decimal, {:null => false, :precision => 30, :scale => 2, :default => 0.0}

      t.timestamps
    end
    add_index :easy_money_periodical_entity_items, [:easy_money_periodical_entity_id], :name => 'idx_empei_1'

  end

  def self.down

    drop_table :easy_money_periodical_entity_items
    drop_table :easy_money_periodical_entities

  end
end