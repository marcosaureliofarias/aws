class RepairEasyMoneySettings < ActiveRecord::Migration[4.2]
  def self.up
    Project.all.each do |project|
      next unless project.module_enabled?(:easy_money)

      if EasyMoneyRatePriority.where(:project_id => project.id).blank?
        EasyMoneyRatePriority.rate_priorities_by_project(nil).copy_to(project)
      end
    end

  end

  def self.down
  end
end
