class CreateEasyReportIssueStatuses < ActiveRecord::Migration[4.2]
  def self.up

    create_table :easy_report_issue_statuses, :force => true do |t|
      t.column :issue_id, :integer, { :null => false }
      t.column :status_time_0, :integer, { :null => true }
      t.column :status_count_0, :integer, { :null => true }
      t.column :status_time_1, :integer, { :null => true }
      t.column :status_count_1, :integer, { :null => true }
      t.column :status_time_2, :integer, { :null => true }
      t.column :status_count_2, :integer, { :null => true }
      t.column :status_time_3, :integer, { :null => true }
      t.column :status_count_3, :integer, { :null => true }
      t.column :status_time_4, :integer, { :null => true }
      t.column :status_count_4, :integer, { :null => true }
      t.column :status_time_5, :integer, { :null => true }
      t.column :status_count_5, :integer, { :null => true }
      t.column :status_time_6, :integer, { :null => true }
      t.column :status_count_6, :integer, { :null => true }
      t.column :status_time_7, :integer, { :null => true }
      t.column :status_count_7, :integer, { :null => true }
      t.column :status_time_8, :integer, { :null => true }
      t.column :status_count_8, :integer, { :null => true }
      t.column :status_time_9, :integer, { :null => true }
      t.column :status_count_9, :integer, { :null => true }
      t.column :status_time_10, :integer, { :null => true }
      t.column :status_count_10, :integer, { :null => true }
      t.column :status_time_11, :integer, { :null => true }
      t.column :status_count_11, :integer, { :null => true }
      t.column :status_time_12, :integer, { :null => true }
      t.column :status_count_12, :integer, { :null => true }
      t.column :status_time_13, :integer, { :null => true }
      t.column :status_count_13, :integer, { :null => true }
      t.column :status_time_14, :integer, { :null => true }
      t.column :status_count_14, :integer, { :null => true }
      t.column :status_time_15, :integer, { :null => true }
      t.column :status_count_15, :integer, { :null => true }
      t.column :status_time_16, :integer, { :null => true }
      t.column :status_count_16, :integer, { :null => true }
      t.column :status_time_17, :integer, { :null => true }
      t.column :status_count_17, :integer, { :null => true }
      t.column :status_time_18, :integer, { :null => true }
      t.column :status_count_18, :integer, { :null => true }
      t.column :status_time_19, :integer, { :null => true }
      t.column :status_count_19, :integer, { :null => true }
      t.column :status_time_20, :integer, { :null => true }
      t.column :status_count_20, :integer, { :null => true }
      t.column :status_time_21, :integer, { :null => true }
      t.column :status_count_21, :integer, { :null => true }
      t.column :status_time_22, :integer, { :null => true }
      t.column :status_count_22, :integer, { :null => true }
      t.column :status_time_23, :integer, { :null => true }
      t.column :status_count_23, :integer, { :null => true }
      t.column :status_time_24, :integer, { :null => true }
      t.column :status_count_24, :integer, { :null => true }
      t.column :status_time_25, :integer, { :null => true }
      t.column :status_count_25, :integer, { :null => true }
      t.column :status_time_26, :integer, { :null => true }
      t.column :status_count_26, :integer, { :null => true }
      t.column :status_time_27, :integer, { :null => true }
      t.column :status_count_27, :integer, { :null => true }
      t.column :status_time_28, :integer, { :null => true }
      t.column :status_count_28, :integer, { :null => true }
      t.column :status_time_29, :integer, { :null => true }
      t.column :status_count_29, :integer, { :null => true }
    end
    add_index :easy_report_issue_statuses, [:issue_id], :unique => true, :name => 'idx_eris_1'

  end

  def self.down
    drop_table :easy_report_issue_statuses
  end
end
