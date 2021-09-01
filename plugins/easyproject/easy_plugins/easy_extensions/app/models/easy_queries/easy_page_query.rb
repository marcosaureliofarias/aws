class EasyPageQuery < EasyQuery

  def initialize_available_filters
    on_filter_group(default_group_label) do
      add_available_filter 'identifier', type: :string, name: EasyPage.human_attribute_name(:identifier)
      add_available_filter 'description', type: :text, name: EasyPage.human_attribute_name(:description)
      add_available_filter 'tags', { type: :list_autocomplete, label: :label_easy_tags, source: 'tags', source_root: '' }
    end
  end

  def available_columns
    unless @available_columns_added
      group = l("label_filter_group_#{self.class.name.underscore}")

      @available_columns = [
          EasyQueryColumn.new(:identifier,
                              sortable: "#{EasyPage.table_name}.identifier",
                              title:    EasyPage.human_attribute_name(:identifier),
                              group:    group),
          EasyQueryColumn.new(:url,
                              sortable: false,
                              title:    EasyPage.human_attribute_name(:url),
                              group:    group),
          EasyQueryColumn.new(:translated_name,
                              sortable: false,
                              title:    EasyPage.human_attribute_name(:translated_name),
                              group:    group),
          EasyQueryColumn.new(:description,
                              sortable: false,
                              title:    EasyPage.human_attribute_name(:description),
                              group:    group),
          EasyQueryColumn.new(:page_scope,
                              sortable: "#{EasyPage.table_name}.page_scope",
                              title:    EasyPage.human_attribute_name(:page_scope),
                              group:    group),
          EasyQueryColumn.new(:tags,
                              preload: [:tags],
                              caption: :label_easy_tags,
                              group:   group)
      ]

      @available_columns_added = true
    end
    @available_columns
  end

  def searchable_columns
    ["#{EasyPage.table_name}.identifier", "#{EasyPage.table_name}.user_defined_name", "#{EasyPage.table_name}.description"]
  end

  def default_list_columns
    super.presence || %w[identifier url translated_name description page_scope]
  end

  def entity
    EasyPage
  end

  def entity_scope
    @entity_scope ||= EasyPage.for_index
  end

end
