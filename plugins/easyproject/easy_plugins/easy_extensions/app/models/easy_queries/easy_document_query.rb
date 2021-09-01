class EasyDocumentQuery < EasyQuery

  def self.permission_view_entities
    :view_documents
  end

  def self.filter_non_restricted_documents(documents, user, row_limit, sort_by)
    documents_count = 0

    documents        = documents.inject(Hash.new { |hash, key| hash[key] = Array.new }) do |mem, var|
      if (row_limit == 0 || documents_count < row_limit) && allow_document?(var, user)
        group = case sort_by
                when 'date'
                  User.current.time_to_date(var.updated_on)
                when 'title'
                  var.title.first.upcase
                when 'author'
                  var.attachments.last && var.attachments.last.author || nil
                when 'project'
                  var.project
                else
                  var.category
                end
        mem[group] << var
        documents_count += 1
      end

      mem
    end
    sorted_keys      = documents.keys.sort do |a, b|
      case sort_by
      when 'category'
        a.position <=> b.position
      when 'project', 'author', 'title'
        a.to_s <=> b.to_s
      else
        a <=> b
      end
    end
    sorted_documents = ActiveSupport::OrderedHash.new
    sorted_keys.each do |k|
      sorted_documents[k] = documents[k]
    end

    return documents_count, sorted_documents
  end

  def query_after_initialize
    super

    if self.new_record? && self.settings[:old_document_query]
      self.sort_criteria                             = { '0' => ['project', 'asc'], '1' => ['', ''], '2' => ['', ''] } if self.sort_criteria.blank?
      self.display_filter_columns_on_index           = false
      self.display_filter_group_by_on_index          = false
      self.display_filter_sort_on_index              = true
      self.display_filter_columns_on_edit            = false
      self.display_filter_group_by_on_edit           = false
      self.display_filter_sort_on_edit               = true
      self.display_filter_settings_on_edit           = false
      self.display_filter_settings_on_index          = false
      self.display_project_column_if_project_missing = false
    end

    self.easy_query_entity_controller = 'easy_documents'
  end

  def initialize_available_filters
    on_filter_group(default_group_label) do
      add_available_filter 'category_id', name: Document.human_attribute_name(:category_id), type: :list, values: Proc.new { DocumentCategory.active.collect { |i| [i.name, i.id.to_s] } }
      add_available_filter 'title', name: Document.human_attribute_name(:title), type: :text
      add_available_filter 'description', name: Document.human_attribute_name(:description), type: :text
      add_available_filter 'created_on', name: Document.human_attribute_name(:created_on), type: :date_period, time_column: true
    end

    unless project
      add_available_filter 'project_id', name: Document.human_attribute_name(:project_id), type: :list_autocomplete, source: 'visible_projects', source_root: 'projects', data_type: :project
    end
    add_custom_fields_filters(DocumentCustomField)
  end

  def initialize_available_columns
    group = l("label_filter_group_#{self.class.name.underscore}")

    add_available_column 'title', caption: :field_title, group: group, sortable: "#{Document.table_name}.title", groupable: "#{Document.table_name}.title"
    add_available_column 'category', caption: :field_category, group: group, sortable: "#{DocumentCategory.table_name}.name", groupable: "#{DocumentCategory.table_name}.name"
    add_available_column 'project', caption: :field_project, group: group, sortable: "#{Project.table_name}.name", groupable: "#{Project.table_name}.id"
    add_available_column EasyQueryDateColumn.new('created_on', caption: :field_created_on, group: group, sortable: "#{Document.table_name}.created_on", groupable: "#{Document.table_name}.created_on")

    add_available_columns DocumentCustomField.sorted.collect { |cf| EasyQueryCustomFieldColumn.new(cf) }
  end

  def default_list_columns
    @default_list_columns ||= %w[project category title created_on attachments]
  end

  def list_columns_changed?
    return false
  end

  def report_support?
    false
  end

  def self.report_support?
    false
  end

  def tiles_support?
    false
  end

  def default_find_include
    %i[project category attachments]
  end

  def searchable_columns
    ["#{Document.table_name}.title"]
  end

  def entity
    Document
  end

  def entity_scope
    @entity_scope ||= (project.nil? ? Document.joins(:project).where(["#{Project.table_name}.easy_is_easy_template = ?", false]) : project.documents).visible
  end

  protected

  def get_custom_sql_for_field(field, operator, value)
    if field == "attachment_created_on"
      db_table = Attachment.table_name
      db_field = 'created_on'
      return sql_for_field(field, operator, value, db_table, db_field)
    end
  end

  def self.allow_document?(doc, user)
    allow = true
    if doc.respond_to?(:active_record_restricted?)
      allow = !doc.active_record_restricted?(user, :read)
    end

    return allow
  end

end
