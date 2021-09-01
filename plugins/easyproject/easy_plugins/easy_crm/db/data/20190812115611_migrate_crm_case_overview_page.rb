# @note creates and applies template for easy-crm-overview and moves current setting from
#   easy-crm-project-overview.where(entity_id: nil)
class MigrateCrmCaseOverviewPage < EasyExtensions::EasyDataMigration
  def up
    crm_overview = EasyPage.find_by(page_name: 'easy-crm-overview')
    crm_project_overview = EasyPage.find_by(page_name: 'easy-crm-project-overview')
    crm_overview_epms = crm_project_overview && EasyPageZoneModule.where(easy_pages_id: crm_project_overview.id,
                                                                         entity_id: nil).any?
    if crm_overview && crm_project_overview && crm_overview_epms
      # create template from current crm overview (project overview where entity is nil)
      copy_params = { easy_pages_id: crm_project_overview.id,
                      copy_from_type: 'regular_page',
                      copy_from_user_id: nil,
                      copy_from_entity_id: nil,
                      copy_from_template_id: nil,
                      template_name: 'Crm Case Original Overview',
                      description: 'Your original Crm Case Dashboard',
                      is_default: '0' }
      page_template = EasyPageTemplate.new
      page_template.safe_attributes = copy_params
      page_template.save

      # available_zones mapping - project-overview to global-overview zones
      zone_id_mapping = {}
      global_crm_overview_zones = EasyPageAvailableZone.where(easy_pages_id: crm_overview.id).
        pluck(:easy_page_zones_id, :id).to_h

      page_template.page_definition.zones.each do |project_zone|
        zone_id_mapping[project_zone.id] = global_crm_overview_zones[project_zone.easy_page_zones_id]
      end

      # available_modules mapping - project-overview to global-overview zones
      available_module_id_mapping = {}
      global_crm_overview_available_modules = EasyPageAvailableModule.where(easy_pages_id: crm_overview.id).
        pluck(:easy_page_modules_id, :id).to_h

      page_template.page_definition.available_modules.each do |project_module|
        mapped_module_id = global_crm_overview_available_modules[project_module.easy_page_modules_id] || project_module.id
        available_module_id_mapping[project_module.id] = mapped_module_id
      end

      # update available_zones and available_modules
      EasyPageTemplateModule.where(easy_page_templates_id: page_template.id).each do |template_module|
        new_zone_id = zone_id_mapping[template_module.easy_page_available_zones_id]
        new_available_module_id = available_module_id_mapping[template_module.easy_page_available_modules_id]
        next unless new_available_module_id && new_zone_id

        template_module.update_columns(easy_page_available_zones_id: new_zone_id,
                                       easy_page_available_modules_id: new_available_module_id)
      end

      # change template target EasyPage to global crm overview
      page_template.update_columns(easy_pages_id: crm_overview.id)

      # apply template to global overview
      EasyPageZoneModule.create_from_page_template(page_template)
    end
  end

  def down
  end
end
