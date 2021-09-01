class AddEasyAgileIssueRatingDefaultSettings < ActiveRecord::Migration[4.2]
  def up
    EasySetting.create name: 'easy_agile_issue_rating_mode', value: 'disabled'
    EasySetting.create name: 'easy_agile_issue_rating_cf', value: nil
  end

  def down
    EasySetting.where(name: 'easy_agile_issue_rating_mode').destroy_all
    EasySetting.where(name: 'easy_agile_issue_rating_cf').destroy_all
  end
end
