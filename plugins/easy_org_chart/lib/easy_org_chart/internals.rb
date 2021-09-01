# Use this module for static methods
module EasyOrgChart
  class << self
    def installed?
      EasyOrgChartNode.table_exists?
    end
  end
end
