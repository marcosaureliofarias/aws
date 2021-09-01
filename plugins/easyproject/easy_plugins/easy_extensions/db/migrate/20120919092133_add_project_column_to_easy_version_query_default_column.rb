class AddProjectColumnToEasyVersionQueryDefaultColumn < ActiveRecord::Migration[4.2]
  def change
    EasySetting.where(:name => 'easy_version_query_list_default_columns').each do |setting|
      setting.update_attributes(:value => ['project'] + setting.value)
    end
  end
end
