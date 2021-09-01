class AddScopeToStatisticsPage < EasyExtensions::EasyDataMigration
  def up
    EasyPage.reset_column_information

    EasyPage.where(:page_name => 'statistics-test-cases').update_all(:page_scope => 'test-cases')
  end
end
