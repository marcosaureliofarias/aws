module EasyEntityImports
  class EasyJiraXmlImporter < EasyJiraXmlImport

    attr_writer :types_to_import

    private

    def run_imports
      import_entities('User', @xml.xpath('//User')) if !@types_to_import || @types_to_import.include?(:users)
      import_entities('Group', @xml.xpath('//Group')) if !@types_to_import || @types_to_import.include?(:groups)
      import_entities('IssueStatus', @xml.xpath('//Status')) if !@types_to_import || @types_to_import.include?(:issue_statuses)
      import_entities('IssuePriority', @xml.xpath('//Priority')) if !@types_to_import || @types_to_import.include?(:issue_priorities)
      import_entities('Tracker', @xml.xpath('//IssueType')) if !@types_to_import || @types_to_import.include?(:trackers)
      import_entities('Project', @xml.xpath('//Project')) if !@types_to_import || @types_to_import.include?(:projects)
      import_entities('Issue', @xml.xpath('//Issue')) if !@types_to_import || @types_to_import.include?(:issues)
      import_entities('TimeEntry', @xml.xpath('//Worklog')) if !@types_to_import || @types_to_import.include?(:issues)
      import_customfields if !@types_to_import || @types_to_import.include?(:custom_fields)
      import_attachments(File.join(File.dirname(file), 'data', 'attachments')) if !@types_to_import || @types_to_import.include?(:attachments)
      import_entities('Journal', @xml.xpath('//Action[@type = "comment"]')) if !@types_to_import || @types_to_import.include?(:issues)
    end

    def get_user_id(jira_login)
      if @results[:users].nil?
        User.like(jira_login).first.try(:id)
      else
        super || User.like(jira_login).first.try(:id)
      end
    end

  end
end
