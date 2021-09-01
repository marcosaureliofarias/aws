require 'rys'

module EasyWatchersListAutocomplete
  class Engine < ::Rails::Engine
    include Rys::EngineExtensions
  
    rys_id 'easy_watchers_list_autocomplete'
  
    initializer 'easy_watchers_list_autocomplete.setup' do
      # Custom initializer
      EasySetting.map do
        key :easy_watchers_list_autocomplete_watchers_groups_limit do
          default 5
        end
        key :easy_watchers_list_autocomplete_watchers_users_limit do
          default 10
        end
      end
    end
  end
end
