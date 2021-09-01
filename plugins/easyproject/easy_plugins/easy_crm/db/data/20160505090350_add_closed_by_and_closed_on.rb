class AddClosedByAndClosedOn < ActiveRecord::Migration[4.2]

  def up
    statuses = EasyCrmCaseStatus.where(:is_closed => true).pluck(:id)
    closed_crm_cases = EasyCrmCase.where("#{EasyCrmCase.table_name}.is_canceled = ? OR #{EasyCrmCase.table_name}.is_finished = ?", true, true).pluck(:id)

    journals = Journal.joins(:details).where(:journals => {:journalized_type => 'EasyCrmCase'}, :journal_details => {:prop_key => 'easy_crm_case_status_id', :value => statuses}).pluck(:journalized_id, :user_id, "#{Journal.table_name}.created_on").uniq.to_a

    journals.concat(Journal.joins(:details).where(:journalized_id => closed_crm_cases, :journal_details => {:prop_key => %w(is_finished is_canceled), :value => '1'}).pluck(:journalized_id, :user_id, "#{Journal.table_name}.created_on").uniq).to_a

    journals.sort_by! { |j| j[2] }

    crm_cases_by_user = Hash.new { |hash, key| hash[key] = Array.new }
    crm_cases_by_created_on = Hash.new { |hash, key| hash[key] = Array.new }

    journals.each do |journalized_id, user_id, created_on|
      crm_cases_by_user[user_id] << journalized_id
      crm_cases_by_created_on[created_on] << journalized_id
    end

    crm_cases_by_user.each do |user_id, ids|
      EasyCrmCase.where(:id => ids).update_all(:easy_closed_by_id => user_id)
    end

    crm_cases_by_created_on.each do |closed_on, ids|
      EasyCrmCase.where(:id => ids).update_all(:closed_on => closed_on)
    end

    EasyCrmCase.where(["#{EasyCrmCase.table_name}.is_canceled = ? OR #{EasyCrmCase.table_name}.is_finished = ? OR #{EasyCrmCase.table_name}.easy_crm_case_status_id IN (?)", true, true, statuses]).where(closed_on: nil).update_all('closed_on = created_at, easy_closed_by_id = author_id')
  end

  def down
    EasyCrmCase.update_all(:easy_closed_by_id => nil, :closed_on => nil)
  end
end
