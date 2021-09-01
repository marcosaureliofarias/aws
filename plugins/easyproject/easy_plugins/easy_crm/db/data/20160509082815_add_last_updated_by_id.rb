class AddLastUpdatedById < ActiveRecord::Migration[4.2]
  def up
    updators_by_crm_case = Hash.new { |mem, key| mem[key] = [] }
    last_crm_cases_by_updators = Hash.new { |mem, key| mem[key] = [] }

    Journal.where(:journalized_type => 'EasyCrmCase').order(:id).pluck(:id, :journalized_id, :user_id).each{|id, crm_case_id, user_id| updators_by_crm_case[crm_case_id] << user_id }

    updators_by_crm_case.each do |crm_case_id, user_ids|
      author_id = user_ids.last
      last_crm_cases_by_updators[author_id] << crm_case_id
    end

    last_crm_cases_by_updators.each do |user_id, crm_case_ids|
      EasyCrmCase.where(id: crm_case_ids).update_all(easy_last_updated_by_id: user_id)
    end
    EasyCrmCase.where(:easy_last_updated_by_id => nil).update_all("easy_last_updated_by_id = author_id")
  end

  def down
    EasyCrmCase.update_all(:easy_last_updated_by_id => nil)
  end
end
