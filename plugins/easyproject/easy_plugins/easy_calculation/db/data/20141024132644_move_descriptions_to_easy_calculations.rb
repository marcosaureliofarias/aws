class MoveDescriptionsToEasyCalculations < EasyExtensions::EasyDataMigration

  def self.up
    EasySetting.transaction do
      positions = ['top', 'bottom']
      positions.each do |position|
        settings = EasySetting.where(:name => "easy_calculation_#{position}_desc")
        settings.find_each(:batch_size => 50) do |s|
          c = EasyCalculation.where(:project_id => s.project_id).first
          c ||= EasyCalculation.new(:project_id => s.project_id)
          c.safe_attributes = {"#{position}_description" => s.value}
          c.save
          s.destroy
        end
      end
    end
  end

  def self.down
  end

end

