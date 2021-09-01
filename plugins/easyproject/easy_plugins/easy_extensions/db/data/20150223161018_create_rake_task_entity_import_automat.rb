class CreateRakeTaskEntityImportAutomat < ActiveRecord::Migration[4.2]
  def up
    t         = EasyRakeTaskEntityImportAutomat.new(:active => true, :settings => {}, :period => :daily, :interval => 1, :next_run_at => Time.now.end_of_day)
    t.builtin = 1
    t.save!
  end

  def down
    EasyRakeTaskEntityImportAutomat.destroy_all
  end
end
