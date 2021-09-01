module EasyCalendar
  module EasyAutoCompletesControllerPatch

    def self.included(base)
      # base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      # base.class_eval do
      #
      # end
    end

    module InstanceMethods

      def room_availability_for_date_time
        start_time = User.current.convert_time_to_user_civil_time_in_zone(DateTime.safe_parse(params[:start_time]))
        end_time = User.current.convert_time_to_user_civil_time_in_zone(DateTime.safe_parse(params[:end_time]))

        limit = EasySetting.value('easy_select_limit').to_i
        term = params[:term].to_s.strip

        rooms = if start_time && end_time
                  EasyRoom.where('easy_rooms.name LIKE ?', "%#{term}%").limit(limit).collect do |r|
                    { value: r.name_with_capacity.html_safe,
                      id: r.id,
                      available: r.available_for_date?(start_time, end_time, params[:easy_meeting_id]), }
                  end
                else
                  {}
                end

        render json: rooms
      end

    end

    # module ClassMethods
    #
    # end

  end

end
RedmineExtensions::PatchManager.register_controller_patch 'EasyAutoCompletesController', 'EasyCalendar::EasyAutoCompletesControllerPatch'
