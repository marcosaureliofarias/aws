# easy_calendar
get 'easy_calendar', :to => 'easy_calendar#index', :as => 'easy_calendar'
get 'easy_calendar/page_layout', :to => 'easy_calendar#edit_page_layout', :as => 'easy_calendar_page_layout'
get 'easy_calendar/feed', :to => 'easy_calendar#feed'
get 'easy_calendar/project_meetings', :to => 'easy_calendar#project_meetings', :as => 'project_meetings_feed'
get 'easy_calendar/room_meetings', :to => 'easy_calendar#room_meetings', :as => 'room_meetings_feed'
get 'easy_calendars.:format', :to => 'easy_calendar#user_availability', :as => 'easy_calendar_ics'
get 'easy_calendar/user_availability', :to => 'easy_calendar#user_availability'
get 'easy_calendar/find_by_worker', :to => 'easy_calendar#find_by_worker'
get 'easy_calendar/get_ics', :to => 'easy_calendar#get_ics', :as => 'easy_calendar_get_ics'
get 'easy_calendar/mini', :to => 'easy_calendar#show', :as => 'mini_easy_calendar'
post 'easy_calendar/save_availability', :to => 'easy_calendar#save_availability'
post 'easy_calendar/save_calendars', :to => 'easy_calendar#save_calendars'

# easy_meetings
resources :easy_meetings do
  member do
    match 'accept', :via => [:post, :get]
    match 'decline', :via => [:post, :get]
  end
end

# easy_rooms
resources :easy_rooms do
  collection do
    get 'availability'
  end
end

# caldav
mount EasyCalendar::Caldav::Handler.new, :at => '/caldav', :as => 'caldav'
match '/.well-known/caldav' => redirect('/caldav/principal'), :via => :propfind

resources :easy_icalendars, only: [:create] do
  get :sync, on: :member
  get :get_item, on: :collection
end
