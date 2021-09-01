class AddIndexesToEasyRakeTasks < ActiveRecord::Migration[4.2]
  def self.up
    add_index :easy_rake_task_infos, [:easy_rake_task_id, :status], name: :index_erti_on_task_id_status
    add_index :easy_rake_task_info_details, [:easy_rake_task_info_id], name: :index_ertid_on_info_id
    add_index :easy_rake_task_info_details, [:status], name: :index_ertid_on_status
  end

  def self.down
    remove_index :easy_rake_task_infos, name: :index_erti_on_task_id_status
    remove_index :easy_rake_task_info_details, name: :index_ertid_on_info_id
    remove_index :easy_rake_task_info_details, name: :index_ertid_on_status
  end
end
