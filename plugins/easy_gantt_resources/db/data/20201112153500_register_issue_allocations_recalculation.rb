class RegisterIssueAllocationsRecalculation < EasyExtensions::EasyDataMigration

  def self.up
    t = EasyRakeTaskIssueAllocationsRecalculation.create!({ active: false,
                                                            period: 'daily',
                                                            interval: 1,
                                                            next_run_at: Time.now.beginning_of_day,
                                                            builtin: 1
                                                          });
  end

  def self.down
    EasyRakeTaskIssueAllocationsRecalculation.destroy_all
  end

end