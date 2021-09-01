class RemoveOldHelpdeskQueries < EasyExtensions::EasyDataMigration

  def self.up
    classes = ['EasyHelpdeskReportQuery', 'EasyHelpdeskReportYearlyQuery', 'EasyHelpdeskReportMonthlyQuery']
    EasyQuery.where(:type => classes).delete_all

    EasySetting.where(:name => 'easy_helpdesk_report_query_list_default_columns').destroy_all
  end

  def self.down
  end

end