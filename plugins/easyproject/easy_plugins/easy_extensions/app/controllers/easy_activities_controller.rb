class EasyActivitiesController < ApplicationController

  accept_rss_auth :events_from_activity_feed_module

  include EasyActivitiesHelper
  helper :activities
  before_action :authorize_global
  before_action :find_activity_feed_page_module, :only => [:events_from_activity_feed_module, :show_selected_event_type], :if => Proc.new { !params[:defaults] }

  def show_toolbar
    options = recent_events_options
    if options.present?
      update_user_preferences_for_recent_events_options(options)
      recent_events_options_in_use = true
    end
    @events_by_day = sort_and_group_events(EasyActivity.last_current_user_events_with_defaults(options))

    respond_to do |format|
      format.js do
        render :show_toolbar, locals: { recent_events_options: options.presence || user_recent_events_options,
                                        recent_events_options_in_use: recent_events_options_in_use }
      end
    end
  end

  def show_selected_event_type
    event_type = params[:event_type_id] || 'all'
    @settings  = @activity_feed_page_module.settings || {}

    @settings['custom_event_types']   = true
    @settings['selected_event_types'] = event_type == 'all' ? EasyActivity.all_visible_event_types(User.current) : [event_type]
    @settings['load_more']            = params[:load_more]
    @settings['current_limit']        = params[:current_limit]

    page_context = {}
    add_global_filters_to_page_context!(page_context)
    @events = EpmActivityFeed.events_for_settings(@settings, User.current, page_context)

    respond_to do |format|
      format.js
    end
  end

  def get_current_user_activities_count
    respond_to do |format|
      format.json {
        # This should be part of EasyBackgroundService now
        render :json => { :current_activities_count => Rails.env.test? ? 0 : EasyActivity.last_current_user_events_with_defaults_count }
      }
    end
  end

  def discart_all_events
    events = EasyActivity.last_current_user_events_with_defaults(recent_events_options)
    events.each do |event|
      if event.respond_to?(:mark_as_read)
        event.mark_as_read
      end
    end

    respond_to do |format|
      format.js
    end
  end

  def events_from_activity_feed_module
    if params[:defaults]
      events = EasyActivity.last_current_user_events_with_defaults(recent_events_options)
    else
      settings = @activity_feed_page_module.settings
      events   = EpmActivityFeed.events_for_settings(settings)
    end
    @events_by_day = sort_and_group_events(events)

    respond_to do |format|
      format.html
      format.atom {
        render_feed(events)
      }
    end
  end

  private

  def find_activity_feed_page_module
    @activity_feed_page_module = EasyPageZoneModule.find(params[:module_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def recent_events_options
    if (recent_events_options = params[:recent_events_options])
      {
        display_read: recent_events_options[:display_read].to_boolean,
        last_x_days: recent_events_options[:last_x_days]
      }
    else
      {}
    end
  end

  def user_recent_events_options
    options = User.current.pref[:recent_events_options]
    options = options.is_a?(Hash) ? options.compact.presence : nil
    options || { display_read: true, last_x_days: 5 }
  end

  def update_user_preferences_for_recent_events_options(recent_events_options)
    return unless recent_events_options.present?

    pref = User.current.pref
    pref[:recent_events_options] = recent_events_options
    pref.save
  end

  def sort_and_group_events(events)
    events.sort_by!(&:event_datetime)
    events.reverse!
    events.group_by { |event| User.current.time_to_date(event_update_datetime(event)) }
  end

end
