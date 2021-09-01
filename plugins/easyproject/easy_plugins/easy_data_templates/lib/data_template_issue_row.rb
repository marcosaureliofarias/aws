require_dependency 'data_template_entity_row_base'

class DataTemplateIssueRow < DataTemplateEntityRowBase

  def prepare_row_for_import(row)
    super
    @entity = Issue.new
    fill_entity(@entity)
  end

  def prepare_row_for_export(issue)
    data = super(issue)
    @datatemplate.assignments.each do |assignment|
      case assignment.entity_attribute_name
      when 'assigned_to_id'
        data[(assignment.file_column_position-1)] = sanitize_clean(issue.assigned_to_id)
      when 'assigned_to_login'
        data[(assignment.file_column_position-1)] = issue.assigned_to_id.blank? ? "" : sanitize_clean(issue.assigned_to.login)
      when 'assigned_to_mail'
        data[(assignment.file_column_position-1)] = issue.assigned_to_id.blank? ? "" : sanitize_clean(issue.assigned_to.mail)
      when 'assigned_to_firstname'
        data[(assignment.file_column_position-1)] = issue.assigned_to_id.blank? ? "" : sanitize_clean(issue.assigned_to.firstname)
      when 'assigned_to_lastname'
        data[(assignment.file_column_position-1)] = issue.assigned_to_id.blank? ? "" : sanitize_clean(issue.assigned_to.lastname)
      when 'author_id'
        data[(assignment.file_column_position-1)] = sanitize_clean(issue.author_id)
      when 'author_login'
        data[(assignment.file_column_position-1)] = sanitize_clean(issue.author.login)
      when 'author_mail'
        data[(assignment.file_column_position-1)] = sanitize_clean(issue.author.mail)
      when 'author_firstname'
        data[(assignment.file_column_position-1)] = sanitize_clean(issue.author.firstname)
      when 'author_lastname'
        data[(assignment.file_column_position-1)] = sanitize_clean(issue.author.lastname)
      when 'description'
        data[(assignment.file_column_position-1)] = sanitize_clean(issue.description)
      when 'due_date'
        data[(assignment.file_column_position-1)] = sanitize_clean(issue.due_date)
      when 'estimated_hours'
        data[(assignment.file_column_position-1)] = sanitize_clean(issue.estimated_hours)
      when 'id'
        data[(assignment.file_column_position-1)] = sanitize_clean(issue.id)
      when 'priority_id'
        data[(assignment.file_column_position-1)] = sanitize_clean(issue.priority_id)
      when 'priority_name'
        data[(assignment.file_column_position-1)] = sanitize_clean(issue.priority.name)
      when 'project_id'
        data[(assignment.file_column_position-1)] = sanitize_clean(issue.project_id)
      when 'project_name'
        data[(assignment.file_column_position-1)] = sanitize_clean(issue.project.name)
      when 'start_date'
        data[(assignment.file_column_position-1)] = sanitize_clean(issue.start_date)
      when 'subject'
        data[(assignment.file_column_position-1)] = sanitize_clean(issue.subject)
      when 'tracker_id'
        data[(assignment.file_column_position-1)] = sanitize_clean(issue.tracker_id)
      when 'tracker_name'
        data[(assignment.file_column_position-1)] = sanitize_clean(issue.tracker.name)
      else
        data[(assignment.file_column_position-1)] = sanitize_clean(issue.custom_value_for(assignment.entity_attribute_name))
      end
    end

    return data
  end

  private

  def fill_entity(issue)
    unless @datatemplate.settings[:encoding] == l(:eady_data_template_encoding)
      ic = Iconv.new(l(:eady_data_template_encoding),@datatemplate.settings['encoding'])
      @datatemplate.assignments.each do |assignment|
        begin
          @row[(assignment.file_column_position-1)] = ic.iconv(@row[(assignment.file_column_position-1)].to_s)
        rescue
          @row[(assignment.file_column_position-1)] = @row[(assignment.file_column_position-1)].to_s
        end
      end
    end

    @datatemplate.assignments.each do |assignment|
      case assignment.entity_attribute_name
      when 'assigned_to_id'
        issue.assigned_to_id ||= @row[(assignment.file_column_position-1)].to_s.strip
      when 'assigned_to_login'
        unless user_find({:login => @row[(assignment.file_column_position-1)].to_s}).nil?
          my_assigned_to_id = user_find({:login => @row[(assignment.file_column_position-1)].to_s.strip}).id
          issue.assigned_to_id ||= my_assigned_to_id
        end
      when 'assigned_to_mail'
        unless user_find({:mail => @row[(assignment.file_column_position-1)].to_s}).nil?
          my_assigned_to_id = user_find({:mail => @row[(assignment.file_column_position-1)].to_s.strip}).id
          issue.assigned_to_id ||= my_assigned_to_id
        end
      when 'assigned_to_firstname'
        unless @datatemplate.assignments.where(:entity_attribute_name => "assigned_to_lastname").blank?
          my_assigned_to_firstname = @datatemplate.assignments.where(:entity_attribute_name => "assigned_to_lastname").first
          unless user_find({:firstname => @row[(assignment.file_column_position-1)].to_s, :lastname => @row[(my_assigned_to_firstname.file_column_position-1)].to_s}).nil?
            my_assigned_to_id = user_find({:firstname => @row[(assignment.file_column_position-1)].to_s.strip, :lastname => @row[(my_assigned_to_firstname.file_column_position-1)].to_s.strip}).id
            issue.assigned_to_id ||= my_assigned_to_id
          end
        end
      when 'assigned_to_lastname'
        unless @datatemplate.assignments.where(:entity_attribute_name => "assigned_to_firstname").blank?
          my_assigned_to_lastname = @datatemplate.assignments.where(:entity_attribute_name => "assigned_to_firstname").first
          unless user_find({:firstname => @row[(assignment.file_column_position-1)].to_s, :lastname => @row[(my_assigned_to_lastname.file_column_position-1)].to_s}).nil?
            my_assigned_to_id = user_find({:firstname => @row[(assignment.file_column_position-1)].to_s.strip, :lastname => @row[(my_assigned_to_lastname.file_column_position-1)].to_s.strip}).id
            issue.assigned_to_id ||= my_assigned_to_id
          end
        end
      when 'author_id'
        my_author_id = @row[(assignment.file_column_position-1)].to_s.strip
        issue.author_id = issue.author_id == 0 ? my_author_id : issue.author_id
      when 'author_login'
        unless user_find({:login => @row[(assignment.file_column_position-1)].to_s.strip}).nil?
          my_author_id = user_find({:login => @row[(assignment.file_column_position-1)].to_s.strip}).id
          issue.author_id = issue.author_id == 0 ? my_author_id : issue.author_id
        end
      when 'author_mail'
        unless user_find({:mail => @row[(assignment.file_column_position-1)].to_s.strip}).nil?
          my_author_id = user_find({:mail => @row[(assignment.file_column_position-1)].to_s.strip}).id
          issue.author_id = issue.author_id == 0 ? my_author_id : issue.author_id
        end
      when 'author_firstname'
        unless @datatemplate.assignments.where(:entity_attribute_name => "author_lastname").blank?
          my_author_lastname = @datatemplate.assignments.where(:entity_attribute_name => "author_lastname").first
          unless user_find({:firstname => @row[(assignment.file_column_position-1)].to_s.strip, :lastname => @row[(my_author_lastname.file_column_position-1)].to_s.strip}).nil?
            my_author_id = user_find({:firstname => @row[(assignment.file_column_position-1)].to_s.strip, :lastname => @row[(my_author_lastname.file_column_position-1)].to_s.strip}).id
            issue.author_id = issue.author_id == 0 ? my_author_id : issue.author_id
          end
        end
      when 'author_lastname'
        unless @datatemplate.assignments.where(:entity_attribute_name => "author_firstname").blank?
          my_author_firstname = @datatemplate.assignments.where(:entity_attribute_name => "author_firstname").first
          unless user_find({:firstname => @row[(my_author_firstname.file_column_position-1)].to_s.strip, :lastname => @row[(assignment.file_column_position-1)].to_s.strip}).nil?
            my_author_id = user_find({:firstname => @row[(my_author_firstname.file_column_position-1)].to_s.strip, :lastname => @row[(assignment.file_column_position-1)].to_s.strip}).id
            issue.author_id = issue.author_id == 0 ? my_author_id : issue.author_id
          end
        end
      when 'description'
        issue.description = @row[(assignment.file_column_position-1)].to_s.strip
      when 'due_date'
        begin
          issue.due_date = @row[(assignment.file_column_position-1)].to_s.strip.to_time
        rescue
          #          chyba, jak ji dam uzivateli?
        end
      when 'estimated_hours'
        issue.estimated_hours = @row[(assignment.file_column_position-1)].to_s.strip
      when 'priority_id'
        issue.priority_id = @row[(assignment.file_column_position-1)].to_s.strip
      when 'priority_name'
        my_priority_id = IssuePriority.where(:name => @row[(assignment.file_column_position-1)].to_s.strip).limit(1).pluck(:id).first
        issue.priority_id = my_priority_id
      when 'project_id'
        my_project = Project.where(:id => @row[(assignment.file_column_position-1)].to_s.strip.to_i).limit(1).pluck(:id).first
        issue.project ||= my_project
      when 'project_name'
        my_project = Project.where(:name => @row[(assignment.file_column_position-1)].to_s.strip).first
        issue.project ||= my_project
      when 'start_date'
        begin
          issue.start_date = @row[(assignment.file_column_position-1)].to_s.strip.to_time
        rescue
          #          chyba, jak ji dam uzivateli?
        end
      when 'subject'
        issue.subject = @row[(assignment.file_column_position-1)]
      when 'tracker_id'
        issue.tracker_id = issue.tracker_id == 0 ? @row[(assignment.file_column_position-1)] : issue.tracker_id
      when 'tracker_name'
        my_tracker_id = Tracker.where(:name => @row[(assignment.file_column_position-1)].to_s).limit(1).pluck(:id).first
        issue.tracker_id = issue.tracker_id == 0 ? my_tracker_id : issue.tracker_id
      else
        fill_custom_field_entity(issue, assignment.entity_attribute_name.to_i, @row[(assignment.file_column_position-1)])
      end
    end
  end

  def fill_custom_field_entity(issue, customfield_id, value)
    cfv = issue.custom_field_values.select{|x| x.custom_field_id == customfield_id}.compact.first
    cfv.value = value unless cfv.nil?
  end

  def sanitize_clean(value)
    Sanitize.clean(value.to_s, :output => :html)
  end

  def user_find(conditions)
    User.where(conditions).first
  end

end