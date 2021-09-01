class CreateEasyRakeTaskComputedFromQuery < ActiveRecord::Migration[5.2]
  def up
    unless EasyRakeTaskComputedFromQuery.exists?
      t = EasyRakeTaskComputedFromQuery.new(active: true, settings: {}, period: :daily, interval: 1, next_run_at: Time.now.beginning_of_day)
      t.builtin = 1
      t.save!
    end
  end

  def down
    EasyRakeTaskComputedFromQuery.destroy_all
  end
end
