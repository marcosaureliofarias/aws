module EasyGanttResources
  module ResourceQueryCommon

    attr_reader :assigned_to

    def assigned_to=(user_id)
      if user_id == 'unassigned'
        @assigned_to = nil
      else
        @assigned_to = user_id.to_i
      end
    end

  end
end
