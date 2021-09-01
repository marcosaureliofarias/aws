class MigrateScrumSettings < ActiveRecord::Migration[4.2]
  def up
    new_settings = Hash.new{ |h, k| h[k] = EasySetting.new(name: 'scrum_settings', project_id: k, value: {}) }
    EasySetting.where(name: 'easy_agile_issue_rating_mode').each do |set|
      new_settings[set.project_id].value['summable_column'] =
        case set.value
        when 'estimated_time_minus_spent_time'
          'remaining_timeentries'
        when 'disabled'
          ''
        when 'value_from_custom_field'
          cf_id = EasySetting.value('easy_agile_issue_rating_cf', set.project_id)
          if cf_id
            'cf_' + cf_id.to_s
          else
            ''
          end
        else
          set.value
        end
    end
    EasySetting.where(name: 'easy_agile_project_cf').each do |set|
      new_settings[set.project_id].value['main_attribute'] = (set.value == '-' ? '' : 'cf_' + set.value.to_s)
    end
    new_settings.each do |pid, set|
      set.save
    end
  end

  def down
    EasySetting.where(name: 'scrum_settings').destroy_all
  end
end
