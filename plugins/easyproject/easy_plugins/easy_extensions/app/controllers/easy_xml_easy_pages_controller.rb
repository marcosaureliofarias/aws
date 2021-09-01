class EasyXmlEasyPagesController < EasyXmlDataController

  private

  def entity_mapping
    'easy_page_mapping'
  end

  def create_exporter
    @exporter = EasyXmlData::EasyPageExporter.new(params['id'])
  end

  def get_filename
    if params[:id]
      page_name = EasyPage.where(id: params[:id]).pluck(:user_defined_name).first
    end

    "#{page_name || 'export'}_#{Time.now}.zip"
  end

end
