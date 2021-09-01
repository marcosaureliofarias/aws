class CleanupEasyMoneyRates < EasyExtensions::EasyDataMigration
  def up
    EasyMoneyRate.where(EasyMoneyRate.arel_table[:unit_rate].eq(0).or(EasyMoneyRate.arel_table[:unit_rate].eq(nil))).delete_all
  end
end
