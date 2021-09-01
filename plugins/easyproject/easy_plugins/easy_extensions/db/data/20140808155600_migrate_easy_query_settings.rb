class MigrateEasyQuerySettings < EasyExtensions::EasyDataMigration
  def self.up
    global_show_sum_row       = EasySetting.value('show_sum_row')
    global_load_groups_opened = EasySetting.value('load_groups_opened')
    EasyQuery.registered_subclasses.each do |q, _|
      q_name = q.underscore
      EasySetting.create! name: "#{q_name}_show_sum_row", value: global_show_sum_row.nil? ? false : global_show_sum_row
      EasySetting.create! name: "#{q_name}_load_groups_opened", value: global_load_groups_opened.nil? ? false : global_load_groups_opened
    end
    EasySetting.where(:name => ['show_sum_row', 'load_groups_opened'], :project_id => nil).destroy_all
  end

  def self.down
    EasyQuery.registered_subclasses.each do |q, _|
      q_name = q.underscore
      EasySetting.where(:name => ["#{q_name}_show_sum_row", "#{q_name}_load_groups_opened"]).destroy_all
    end
  end
end
