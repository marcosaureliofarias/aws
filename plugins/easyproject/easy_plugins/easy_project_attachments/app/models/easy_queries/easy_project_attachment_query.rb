class EasyProjectAttachmentQuery < EasyQuery

  def entity_easy_query_path(options)
    polymorphic_path([self.project, :easy_project_attachments], options)
  end

  def self.permission_view_entities
    :view_easy_project_attachments
  end

  def query_after_initialize
    super
    self.easy_query_entity_controller = 'easy_project_attachments'
    self.require_is_tagged            = true
  end

  def additional_statement
    unless @additional_statement_added
      @additional_statement = "#{Attachment.table_name}.container_type IN (#{Attachment.allowed_containers_for_query.map{|container| "'#{container}'"}.join(',')})"
      @additional_statement << ("AND " + project_statement) unless project_statement.blank?
      @additional_statement_added = true
    end
    @additional_statement
  end

  def initialize_available_filters
    on_filter_group(default_group_label) do
      add_available_filter 'container_type', name: l(:label_easy_project_attachments_container_type), type: :list, values: Attachment.allowed_containers_for_query
      add_available_filter 'filename', name: Attachment.human_attribute_name(:filename), type: :text
      add_available_filter 'filesize', name: Attachment.human_attribute_name(:filesize), type: :integer
      add_available_filter 'downloads', name: Attachment.human_attribute_name(:downloads), type: :integer
      add_available_filter 'created_on', name: Attachment.human_attribute_name(:created_on), type: :date_period
      add_principal_autocomplete_filter 'author_id',
                                        name: Attachment.human_attribute_name(:author_id)
      unless project
        add_available_filter 'project_id', name: Attachment.human_attribute_name(:project_id), type: :list_autocomplete, source: 'visible_projects', source_root: 'projects'
      end
    end

    add_custom_fields_filters(AttachmentCustomField)
    add_associations_filters(EasyDocumentQuery, association_name: :document)
  end

  def initialize_available_columns
    group = l("label_filter_group_#{self.class.name.underscore}")
    group_user = l('label_user_plural')

    add_available_column('container_type', title: l(:label_easy_project_attachments_container_type), sortable: "#{Attachment.table_name}.container_type", groupable: true, group: group)
    add_available_column('container_link', title: l(:label_easy_project_attachments_container_link), group: group)
    add_available_column('filename', sortable: "#{Attachment.table_name}.filename", groupable: true, group: group)
    add_available_column('filesize', sortable: "#{Attachment.table_name}.filesize", group: group)
    add_available_column('downloads', sortable: "#{Attachment.table_name}.downloads", group: group)
    add_available_column('author', sortable: lambda { User.fields_for_order_statement }, group: group_user)
    add_available_column('description', group: group)
    add_available_column('created_on', sortable: "#{Attachment.table_name}.created_on", default_order: 'desc', group: group)
    add_available_column('project', sortable: "#{Project.table_name}.name", groupable: "#{Project.table_name}.id", group: group)
    add_available_column('thumbnail', group: group)
    @available_columns.concat(AttachmentCustomField.all.collect { |cf| EasyQueryCustomFieldColumn.new(cf) })

    group = l(:label_filter_group_easy_document_query)
    add_available_column('document.title', title: Document.human_attribute_name(:title), sortable: "#{Document.table_name}.title", group: group, assoc: :document)
    add_available_column('document.category', title: Document.human_attribute_name(:category), group: group, assoc: :document)
    add_available_column('document.created_on', title: Document.human_attribute_name(:created_on), sortable: "#{Document.table_name}.created_on", group: group, assoc: :document)
    @available_columns.concat(DocumentCustomField.visible.sorted.to_a.collect { |cf| EasyQueryCustomFieldColumn.new(cf, group: l(:label_filter_group_easy_document_query_custom_fields), assoc: :document, groupable: false) })

  end

  def default_list_columns
    @default_list_columns = super
    @default_list_columns << 'thumbnail'
  end

  def searchable_columns
    ["#{Attachment.table_name}.filename",
     "#{Attachment.table_name}.description",
     "#{User.table_name}.firstname",
     "#{User.table_name}.lastname",
     "#{User.table_name}.login"]
  end

  def entity
    Attachment
  end

  def entity_scope
    @entity_scope ||= Attachment.joins(:project).visible_for_query.where(["#{Project.table_name}.easy_is_easy_template = ?", false])
  end

  def self.chart_support?
    true
  end

  def self.report_support?
    false
  end

  def default_find_include
    [:author, :document]
  end

  protected

  def project_statement
    return nil unless self.project

    sql = "CASE #{Attachment.table_name}.container_type "
    Attachment.allowed_containers_for_query.each do |cont_type|
      sql << "WHEN '#{cont_type}' THEN EXISTS(SELECT i.id FROM #{cont_type.safe_constantize.table_name} i WHERE i.id = #{Attachment.table_name}.container_id AND i.project_id = #{self.project.id}) "
    end
    sql << "END "
  end

end
