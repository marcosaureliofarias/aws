class EasyXmlEasyPrintableTemplatesController < EasyXmlDataController

  private

  def create_exporter
    @exporter = EasyXmlData::EasyPrintableTemplateExporter.new(params[:id])
  end

  def get_filename
    if params[:id]
      template_name = EasyPrintableTemplate.find_by(id: params[:id])
      filename = "#{template_name.name}_#{Time.now}.zip" if template_name
    end
    filename || "export_#{Time.now}.zip"
  end

end
