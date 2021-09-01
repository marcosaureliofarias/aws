class TestCasesStatisticsEasyPageBuiltIn < EasyExtensions::EasyDataMigration
  def up
    EasyPage.reset_column_information

    EasyPage.where(page_name: 'statistics-test-cases').update_all(page_scope: nil, has_template: true)
  end

  def down
    EasyPage.reset_column_information

    EasyPage.where(page_name: 'statistics-test-cases').update_all(page_scope: 'test-cases', has_template: false)
  end
end
