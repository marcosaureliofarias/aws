# frozen_string_literal: true

module ResourceReportHelper

  def get_epm_resource_report_toggling_container_options(page_module, **options)
    tc_options = {}

    if !options[:edit]
      tc_options[:heading] = page_module.settings.dig('config', 'title')
    end

    tc_options
  end

end
