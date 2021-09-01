class EasyRakeTaskEntityImportAutomat < EasyRakeTask

  def execute
    results = Hash.new
    EasyEntityImport.where(:is_automatic => true).where('api_url IS NOT NULL').each do |easy_entity_import|
      output                           = easy_entity_import.import
      results[easy_entity_import.name] = output.values.select { |k| !k.new_record? }.count
    end
    results
  end
end
