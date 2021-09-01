class MigrateEasyQuery < EasyExtensions::EasyDataMigration
  def self.up
    Query.reset_column_information
    ProjectQuery.reset_column_information
    UserQuery.reset_column_information
    EasyQuery.reset_column_information

    migrate_queries([IssueQuery, TimeEntryQuery, ProjectQuery, UserQuery])
  end

  def self.down
  end

  def self.to_new_easy_query(from, target_klass = nil)
    attributes   = from.class.attribute_names & %w(project_id name filters user_id visibility column_names sort_criteria group_by)
    parameters   = attributes.inject({}) { |acc, attr| acc[attr.to_sym] = from.send(attr); acc }
    target_klass ||= "Easy#{from.class.name}".constantize
    target_klass.new(parameters)
  end

  def self.migrate_queries(query_klasses)
    query_klasses.each do |query_klass|
      query_klass.all.each do |query|
        nq = to_new_easy_query(query)

        if nq.save(validate: false)
          query.destroy
        end
      end
    end
  end
end
