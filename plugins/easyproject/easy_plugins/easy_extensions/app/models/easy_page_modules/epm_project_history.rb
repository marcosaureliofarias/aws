class EpmProjectHistory < EasyPageModule

  def category_name
    @category_name ||= 'projects'
  end

  def get_show_data(settings, user, page_context = {})
    if page_zone_module && !page_zone_module.entity_id.blank?
      project = page_context[:project] || Project.find(page_zone_module.entity_id)
      limit   = settings["row_limit"].to_i
      limit   = 10 if limit == 0
      limit   = 1000 if (limit < 0 || limit > 1000)

      journals = project.prepare_journals limit

      all_journals_shown = project.journals.size <= limit

      { project: project, journals: journals, all_journals_shown: all_journals_shown, journals_limit: limit }
    end
  end

  def get_edit_data(settings, user, page_context = {})
    row_limit = settings["row_limit"] || 10
    { :row_limit => row_limit }
  end

end
