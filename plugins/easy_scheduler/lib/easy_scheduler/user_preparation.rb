module EasyScheduler
  class UserPreparation

    attr_reader :selected_user_ids, :selected_additional_options
    delegate :user_options_with_name, to: :class
    delegate :add_principals_from_options, to: :class

    def initialize(settings)
      @selected_user_ids = Array(settings.dig('query_settings', 'settings', 'selected_principal_ids')) || []
      @selected_user_ids.reject!(&:blank?)
      @selected_additional_options = user_options_with_name.map {|opt| @selected_user_ids.delete(opt) }.compact
    end

    def selected_principal_options
      options = []
      principals = selected_principals(false)
      add_additional_select_options(options, selected_additional_options)    

      principals.each { |principal| options << { id: principal.id, value: principal.name } }
      options
    end

    def selected_principals(from_options = true)
      if from_options
        add_principals_from_options(selected_user_ids, selected_additional_options)
      end

      user_ids = Principal.from('groups_users').
                           where(groups_users: { group_id: selected_user_ids }).
                           pluck(:user_id)
      User.visible.where(id: user_ids.concat(selected_user_ids))
    end

    def self.add_principals_from_options(user_ids_container, options = [])
    end

    def add_additional_select_options(options_container = [], selected_additional_options = [])
    end

    # assignees displayed in scheduler are taken from local storage
    # local storage reloaded after settings changed(edit button click) and after assignee changed from user autocomplete
    # for some options (e.g org chart subordinates) local storage should be always reloaded, because org chart structure can be changed
    def need_to_reload_assignees?
      false
    end

    def self.user_options_with_name
      []
    end
  end
end