class EasyXmlEasyPageTemplatesController < EasyXmlDataController

  private

  def entity_mapping
    'easy_page_mapping'
  end

  def create_exporter
    @exporter = EasyXmlData::EasyPageTemplateExporter.new(params['id'])
  end

  def get_filename
    if params[:id]
      template_name = EasyPageTemplate.where(id: params[:id]).pluck(:template_name).first
      filename      = "#{template_name}_#{Time.now}.zip" if template_name
    end
    filename
  end

end
