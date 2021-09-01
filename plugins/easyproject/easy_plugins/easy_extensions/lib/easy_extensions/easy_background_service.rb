module EasyExtensions
  ##
  # EasyExtensions::EasyBackgroundService
  #
  # For small service background requests
  #
  # == Usage:
  #
  #   # In ruby
  #   EasyExtensions::EasyBackgroundService.add(NAME) do
  #     includes do
  #       # Includes for controller
  #     end
  #
  #     active_if do
  #       # Conditions
  #     end
  #
  #     execution do
  #       # Preparing data for JS
  #     end
  #   end
  #
  #   # In JS
  #   EASY.backgroundServices.add(NAME,
  #       function(data){
  #         // Handle prepared data
  #       },
  #
  #       function(params){
  #         // Add some data to params for ruby
  #       }
  #     )
  #
  # == Flow:
  #
  #   Page request
  #     --> Finding active services (rails view)
  #       --> Collection additional data (js)
  #         --> Request to server (js)
  #           --> Prepare data (ruby)
  #             --> Handle result (js)
  #
  class EasyBackgroundService

    class_attribute :services
    self.services = {}

    def self.active(context)
      services.select do |_, service|
        context.instance_eval(&service.active_if)
      end
    end

    def self.add(name, &block)
      service = new(name)
      service.instance_eval(&block)

      services[name] = service
    end

    def initialize(name)
      @name = name

      @includes  = proc { [] }
      @active_if = proc { true }
      @execution = proc {}
    end

    def includes(&block)
      @includes = block if block_given?
      @includes
    end

    def active_if(&block)
      @active_if = block if block_given?
      @active_if
    end

    def execution(&block)
      @execution = block if block_given?
      @execution
    end

  end
end

# ----------------------------------------------------------------------------
# Activity count to sidebar

EasyExtensions::EasyBackgroundService.add(:easy_activity) do

  active_if do
    !in_mobile_view? && User.current.logged? && User.current.allowed_to_globally?(:view_project_activity) && User.current.internal_client?
  end

  execution do
    if Rails.env.test?
      { current_activities_count: 0 }
    else
      { current_activities_count: EasyActivity.last_current_user_events_with_defaults_count }
    end
  end

end

# ----------------------------------------------------------------------------
# Issue timer for sidebar

EasyExtensions::EasyBackgroundService.add(:easy_issue_timer) do

  active_if do
    User.current.logged?
  end

  execution do
    scope = EasyIssueTimer.running(User.current.id)
    {
        running_count: scope.count,
        is_active:     scope.where(paused_at: nil).exists?
    }
  end

end

# ----------------------------------------------------------------------------
# Attendace statuse to users

EasyExtensions::EasyBackgroundService.add(:attendance_statuses) do

  includes do
    EasyAttendancesHelper
  end

  active_if do
    EasyAttendance.enabled? && User.current.logged? && User.current.allowed_to_globally?(:view_easy_attendances)
  end

  execution do
    result = {}
    if params[:user_ids_on_page].present?
      users = User.where(id: Array(params[:user_ids_on_page])).to_a

      User.load_current_attendance(users)
      User.load_last_today_attendance_to_now(users)

      users.each do |user|
        result[user.id] = easy_attendance_user_status_indicator(user)
      end
    end

    result
  end

end

# ----------------------------------------------------------------------------
# Broadcasts

EasyExtensions::EasyBackgroundService.add(:easy_broadcast) do

  active_if do
    User.current.logged? && User.current.allowed_to_globally?(:view_easy_attendances)
  end

  execution do
    broadcasts = EasyBroadcast.active_for_current_user.pluck(:id, :message)
    broadcasts.map { |id, message| { id: id, message: message } }
  end

end


# ----------------------------------------------------------------------------
# Easy Page User Tabs

EasyExtensions::EasyBackgroundService.add(:easy_page_user_tabs) do
  active_if do
    User.current.easy_page_tabs.exists? && (User.current.logged? || !Setting.login_required?)
  end

  execution do
    User.current.easy_page_tabs.sorted.map do |tab|
      view_context.link_to tab.name, view_context.home_path(:t => tab.position), :class => "icon icon-file easy-page-user-tab-#{tab.id}"
    end
  end
end
