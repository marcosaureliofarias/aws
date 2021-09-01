class ChangeDefaultFilterForEasyVersionQuery < ActiveRecord::Migration[4.2]
  def up
    EasySetting.where(:name => 'easy_version_query_default_filters').each do |s|
      s.value = { 'status' => { :operator => '=', :values => ['open'] } }
      s.save!
    end
  end

  def down
  end
end
