class EpmDocuments < EpmEasyQueryBase

  def category_name
    @category_name ||= 'others'
  end

  def permissions
    @permissions ||= [:view_documents]
  end

  def show_path
    "easy_page_modules/#{category_name}/#{module_name}_show"
  end

  def additional_basic_attributes_path
    "easy_page_modules/#{category_name}/#{module_name}_additional_basic_attributes"
  end

  def page_module_toggling_container_options_helper_method
    'get_epm_easy_query_base_toggling_container_options'
  end

  def get_show_data(settings, user, page_context = {})
    row_limit = settings['row_limit'].to_i

    if settings['query_type'] == '2'
      query         = EasyDocumentQuery.new(:name => settings['query_name'])
      query.project = page_context[:project] if page_context[:project]
      query.from_params(settings)
      query.additional_statement = Project.allowed_to_condition(user, :view_documents)
      documents                  = query.entities({ :include => [:project, :category, { :attachments => :versions }] })

      documents_count, documents = EasyDocumentQuery.filter_non_restricted_documents(documents, user, row_limit, settings['sort_by'])
    elsif settings['query_id'].present? && query = EasyDocumentQuery.find_by(:id => settings['query_id'])
      query.additional_statement = Project.allowed_to_condition(user, :view_documents)
      query.project              = page_context[:project] if page_context[:project]
      documents                  = query.entities({ :include => [:project, :category, { :attachments => :versions }] })

      documents_count, documents = EasyDocumentQuery.filter_non_restricted_documents(documents, user, row_limit, settings['sort_by'])
    else
      documents = Document.visible.preload([:project, :category, { :attachments => :versions }]).order("#{Document.table_name}.created_on DESC")
      documents = documents.where(:project_id => page_context[:project].id) if page_context[:project]

      if row_limit > 0
        documents = documents.first(row_limit)
      else
        documents = documents.to_a
      end

      documents_count = documents.count

      case settings['sort_by']
      when 'date'
        documents = documents.group_by { |d| d.updated_on.to_date }
      when 'title'
        documents = documents.group_by { |d| d.title.first.upcase }
      when 'author'
        documents = documents.select { |d| d.attachments.any? }.group_by { |d| d.attachments.last.author }
      when 'project'
        documents = documents.select { |d| d.attachments.any? }.group_by { |d| d.project }
      else
        documents = documents.group_by(&:category)
      end
    end

    return { :documents => documents, :documents_count => documents_count, :query => query }
  end

  def get_edit_data(settings, user, page_context = {})
    query                      = EasyDocumentQuery.new(:name => (settings['query_name'] || '_'), settings: { old_document_query: true })
    query.additional_statement = Project.allowed_to_condition(user, :view_documents)
    query.export_formats       = {}
    query.project              = page_context[:project] if page_context[:project]
    query.from_params(settings) if settings['query_type'] == '2'
    return { :query => query }
  end

end
