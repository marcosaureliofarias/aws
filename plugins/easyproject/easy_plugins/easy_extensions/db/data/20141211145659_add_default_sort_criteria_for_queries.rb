class AddDefaultSortCriteriaForQueries < ActiveRecord::Migration[4.2]

  MIGRATION_DATA = {
      'easy_cash_desk_query'             => [['name', 'asc']],
      'easy_cash_desk_transaction_query' => [['spent_on', 'asc']],
      'easy_contact_query'               => [['firstname', 'asc']],
      'easy_attendance_query'            => [['arrival', 'desc']],
      'easy_document_query'              => [['category', 'asc'], ['title', 'asc']],
      'easy_group_query'                 => [['lastname', 'asc']],
      'easy_time_entry_base_query'       => [['spent_on', 'asc']],
      'easy_version_query'               => [['project', 'asc'], ['name', 'asc']],
      'easy_invoice_query'               => [['number', 'asc'], ['desc', 'asc']]
  }

  def up
    # Create all missing criteria
    # NOT only those defined on MIGRATION_DATA
    EasyQuery.create_missing_sorting_criteria!(MIGRATION_DATA)
  end

  def down
  end
end
