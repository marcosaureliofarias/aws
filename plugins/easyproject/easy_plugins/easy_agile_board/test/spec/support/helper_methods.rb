module AgileHelperMethods

  def self.swimlane_names
    EasyIssueQuery.available_swimlanes.map{|swimlane| swimlane[:value] }
  end

end
