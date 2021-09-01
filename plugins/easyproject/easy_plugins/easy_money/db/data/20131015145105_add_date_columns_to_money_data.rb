class AddDateColumnsToMoneyData < ActiveRecord::Migration[4.2]
  def self.up

    EasyMailer.with_deliveries(false) do
      [EasyMoneyExpectedExpense, EasyMoneyExpectedRevenue, EasyMoneyOtherExpense, EasyMoneyOtherRevenue].each do |t|
        say_with_time("update '#{t.name}'") do
          t.where(t.arel_table[:spent_on].not_eq(nil)).find_each(:batch_size => 50) do |m|
            spent_on = m.spent_on
            m.update_column(:tyear,  spent_on ? spent_on.year : nil)
            m.update_column(:tmonth, spent_on ? spent_on.month : nil)
            m.update_column(:tweek,  spent_on ? Date.civil(spent_on.year, spent_on.month, spent_on.day).cweek : nil)
            m.update_column(:tday,   spent_on ? spent_on.day : nil)
          end
        end
      end
    end

  end

  def self.down

  end
end
