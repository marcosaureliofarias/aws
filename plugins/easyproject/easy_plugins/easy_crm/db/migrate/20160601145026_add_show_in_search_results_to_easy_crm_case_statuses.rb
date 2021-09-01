class AddShowInSearchResultsToEasyCrmCaseStatuses < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_crm_case_statuses, :show_in_search_results, :boolean, :default => false
  end
end
