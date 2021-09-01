class RemoveDuplicatedRates < EasyExtensions::EasyDataMigration
  def up
    distinct_columns = 'entity_id, entity_type, rate_type_id, project_id'
    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute("UPDATE easy_money_rates SET project_id = 0 WHERE project_id IS NULL")
      ActiveRecord::Base.connection.execute(<<-SQL)
          DELETE FROM easy_money_rates
          WHERE easy_money_rates.id NOT IN (
            SELECT * FROM (
              SELECT MAX(easy_money_rates.id)
              FROM easy_money_rates
              GROUP BY #{distinct_columns}
            ) AS r
          )
      SQL
      ActiveRecord::Base.connection.execute("UPDATE easy_money_rates SET project_id = NULL WHERE project_id = 0")
    end
  end

  def down
  end
end
