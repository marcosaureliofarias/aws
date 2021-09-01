class RegisterEasyQuerySnapshot < EasyExtensions::EasyDataMigration
  def self.up

    t         = EasyRakeTaskEasyQuerySnapshot.new(active:      true, settings: {}, period: :hourly, interval: 1,
                                                  next_run_at: Time.now.beginning_of_day)
    t.builtin = 1
    t.save!

  end

  def self.down

    EasyRakeTaskEasyQuerySnapshot.destroy_all

  end

end
