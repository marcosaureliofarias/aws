class EasyRakeTaskEasyEntityAction < EasyRakeTask

  def execute
    EasyEntityAction.active.run_now.find_each(:batch_size => 1) do |easy_entity_action|
      nextrun_at = EasyUtils::DateUtils.calculate_from_period_options(Date.today, easy_entity_action.period_options)
      easy_entity_action.update_columns(:nextrun_at => nextrun_at)

      easy_entity_action.execute_all

      easy_entity_action.update_columns(:last_executed => Time.now)
    end

    true
  end

end
