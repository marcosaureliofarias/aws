class EasyPrintableTemplateQuery < EasyQuery

  def initialize_available_filters
    on_filter_group(default_group_label) do
      add_available_filter 'project_id', type: :list_autocomplete, time_column: true, order: 1, source: 'visible_projects', source_root: 'projects'
      add_available_filter 'author_id', type: :list_autocomplete, order: 2, source: 'visible_principals', source_root: 'users', name: l(:'activerecord.attributes.easy_printable_template.author')
      add_available_filter 'name', type: :string, order: 4, name: l(:'activerecord.attributes.easy_printable_template.name')
      add_available_filter 'private', type: :boolean, order: 5, name: l(:'activerecord.attributes.easy_printable_template.private')
      add_available_filter 'pages_orientation', type: :list, order: 6, values: values_for_pages_orientations, name: l(:'activerecord.attributes.easy_printable_template.pages_orientation')
      add_available_filter 'pages_size', type: :list, order: 7, values: [%w(A3 a3), %w(A4 a4)], name: l(:'activerecord.attributes.easy_printable_template.pages_size')
    end
  end

  def initialize_available_columns
    on_column_group(default_group_label) do
      add_available_column 'project', sortable: "#{Project.table_name}.name"
      add_available_column 'name', sortable: "#{EasyPrintableTemplate.table_name}.name", caption: :'activerecord.attributes.easy_printable_template.name'
      add_available_column 'description', caption: :'activerecord.attributes.easy_printable_template.description'
      add_available_column 'category_caption', groupable: "#{EasyPrintableTemplate.table_name}.category", caption: :'activerecord.attributes.easy_printable_template.category'
      add_available_column 'private', sortable: "#{EasyPrintableTemplate.table_name}.private", caption: :'activerecord.attributes.easy_printable_template.private'
      add_available_column 'pages_orientation', sortable: "#{EasyPrintableTemplate.table_name}.pages_orientation", caption: :'activerecord.attributes.easy_printable_template.pages_orientation'
      add_available_column 'pages_size', sortable: "#{EasyPrintableTemplate.table_name}.pages_size", caption: :'activerecord.attributes.easy_printable_template.pages_size'
    end

    on_column_group(l('label_user_plural')) do
      add_available_column 'author', sortable: lambda{User.fields_for_order_statement}, caption: :'activerecord.attributes.easy_printable_template.author'
    end
  end

  def entity
    EasyPrintableTemplate
  end

  def entity_easy_query_path(options)
    easy_printable_templates_path options
  end

  def default_find_include
    [:project, :author]
  end

  def searchable_columns
    ["#{Project.table_name}.name", "#{User.table_name}.firstname", "#{User.table_name}.lastname", "#{EasyPrintableTemplate.table_name}.name"]
  end

  def self.list_support?
    false
  end

  def self.report_support?
    false
  end

  private

  def values_for_pages_orientations
    [[EasyPrintableTemplate.translate_pages_orientation(EasyPrintableTemplate::PAGES_ORIENTATION_PORTRAIT), EasyPrintableTemplate::PAGES_ORIENTATION_PORTRAIT],
     [EasyPrintableTemplate.translate_pages_orientation(EasyPrintableTemplate::PAGES_ORIENTATION_LANDSCAPE), EasyPrintableTemplate::PAGES_ORIENTATION_LANDSCAPE]]
  end

end
