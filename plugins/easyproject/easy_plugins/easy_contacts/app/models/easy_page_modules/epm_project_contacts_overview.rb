class EpmProjectContactsOverview < EpmEasyQueryBase

  def category_name
    @category_name ||= 'contacts'
  end

  def permissions
    @permissions ||= [:view_easy_contacts]
  end

  def get_edit_data(settings, user, page_context = {})
    query = EasyContactQuery.new(:name => settings['query_name'] || '')

    if page_zone_module && page_zone_module.entity_id.present?
      @project = Project.find(page_zone_module.entity_id)
    end

    query.from_params(settings) if settings['query_type'] == '2'

    query.project = @project
    query.available_filters.delete_if {|k,v| k == 'project_groups'} if @project

    return {:query => query, :project => @project}
  end

  def get_show_data(settings, user, page_context = {})
    row_limit = settings['row_limit'].blank? ? 10 : settings['row_limit'].to_i
    row_limit = (row_limit <= 0) ? nil : row_limit
    query = EasyContactQuery.new(:name => (settings['query_name'] || '_'))

      if settings['query_type'] == '2'
        query.from_params(settings)
      elsif !settings['query_id'].blank?
        begin
          query = EasyContactQuery.find(settings['query_id'])
        rescue ActiveRecord::RecordNotFound
        end
      end

      if page_zone_module && page_zone_module.entity_id.present?
        @project = Project.find(page_zone_module.entity_id)
      end

      query = self.class.add_query_scope(query, @project || user)

      return {:query => query, :entities => query.prepare_html_result(:limit => row_limit), :project => @project}
  end

  def self.add_query_scope(query, project=nil)
    assigned_contacts_ids = EasyContactEntityAssignment.where(:entity_type => 'Project', :entity_id => project.id).pluck(:easy_contact_id)
    query.add_additional_scope(:id => assigned_contacts_ids)
    query
  end

end
