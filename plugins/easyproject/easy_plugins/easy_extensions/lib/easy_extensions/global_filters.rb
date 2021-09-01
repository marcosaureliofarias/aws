module EasyExtensions
  class GlobalFilters

    @@all = {}.with_indifferent_access

    def self.all
      @@all
    end

    def self.register(klass)
      instance             = klass.new
      @@all[instance.type] = instance
    end

    def self.prepare_available_filters(view_context:)
      result = {}
      all.each do |type, instance|
        result[type] = instance.prepare_available_filters(view_context: view_context)
      end
      result
    end

    def self.prepare_saved_filters(saved)
      if !saved.is_a?(Hash)
        return
      end

      result = saved.deep_dup
      result.select! do |_, options|
        instance = all[options['type']]

        if instance
          instance.prepare_saved_filters!(options)
          true
        else
          false
        end
      end

      result.each do |_, options|
        options['translated_name'] = get_translated_name(options['name'])
      end

      result
    end

    # Prepare query settings
    # Transform from previous version
    #
    def self.prepare_query_filters(filters)
      return {} if !filters.is_a?(Hash)

      filters.transform_values do |value|
        if value.is_a?(Hash)
          # OK
          value
        else
          { 'filter' => value }
        end
      end
    end

    # Get or handle active filters from params
    #
    # params = {'global_filter_1'=>'a', 'global_filter_2'=>'b', 'other'=>'c'}
    #
    # active_filters_from_params(params)
    # # => {'global_filter_1'=>1, 'global_filter_2'=>2}
    #
    # active_filters_from_params(params) do |key, filter_id, value|
    #   key       # => global_filter_1
    #   filter_id # => 1
    #   value     # => 'a'
    #   ...
    # end
    #
    def self.active_filters_from_params(params)
      params.select do |key, value|
        if key.start_with?('global_filter_') && key =~ /\Aglobal_filter_(\d+)\Z/
          yield(key, $1, value) if block_given?
          true
        end
      end
    end

    def self.render_type(type, **options)
      instance = all[type]
      instance && instance.render(**options)
    end

    def self.get_translated_name(name)
      name = I18n.t(name.remove('I18n:'), default: '') if name&.starts_with?('I18n:')
      name.presence
    end

    # =========================================================================
    # Base

    class BaseType

      def name
        raise NotImplementedError
      end

      def type
        raise NotImplementedError
      end

      def prepare_available_filters(view_context:)
        {}
      end

      def prepare_saved_filters!(options)
        options['selected_value'] = options['default_value']
      end

      def render(**options)
        options[:view_context].render 'global_filters/types/base',
                                      name:             name_for_render(**options),
                                      field:            field_for_render(**options),
                                      additional_class: additional_class
      end

      private

      def additional_class
        ''
      end

      def name_for_render(**options)
        GlobalFilters.get_translated_name(options[:filter_options]['name'])
      end

      def field_for_render(**options)
      end

    end

    # =========================================================================
    # AutoComplete

    class AutoCompleteType < BaseType

      def prepare_available_filters(view_context:)
        {
            name:                      name,
            autocomplete:              true,
            autocomplete_path:         view_context.easy_autocomplete_path(autocomplete_action, **autocomplete_action_options),
            autocomplete_root_element: autocomplete_root
        }
      end

      def prepare_saved_filters!(options)
        default_value = options['default_value']

        if default_value.present?
          entity = find_entity(default_value)

          if entity
            options['selected_value'] = [{ id: entity.id, value: entity.to_s }]
          end
        end
      end

      private

      def find_entity(value)
        raise NotImplementedError
      end

      def autocomplete_action
        raise NotImplementedError
      end

      def autocomplete_root
        raise NotImplementedError
      end

      def autocomplete_action_options
        {}
      end

      def autocomplete_action_options
        { include_system_options: 'no_filter' }
      end

      def field_for_render(**options)
        h = options[:view_context]

        entity = find_entity(options[:selected])

        if entity
          selected = [{ id: entity.id, value: entity.to_s }]
        else
          selected = [{ id: '', value: "--- #{I18n.t(:label_in_modules)} ---" }]
        end

        h.autocomplete_field_tag(
            "global_filter_#{options[:filter_id]}",
            h.easy_autocomplete_path(autocomplete_action, **autocomplete_action_options),
            selected,
            rootElement: autocomplete_root,
            multiple:    false,
            preload:     false
        )
      end

    end

    # =========================================================================
    # DatePeriod

    class DatePeriodType < BaseType

      def name
        I18n.t(:label_date)
      end

      def type
        :date_period
      end

      def prepare_available_filters(view_context:)
        {
            name:                  name,
            select_values:         options_for_period_select(view_context, no_html: true),
            select_values_grouped: true
        }
      end

      private

      def options_for_period_select(view_context, selected: nil, no_html: true)
        other_items = [["--- #{I18n.t(:label_in_modules)} ---", '']]

        # Small workaround if somebody set chart#onclick
        if selected && selected.include?('|')
          other_items.unshift([I18n.t(:label_range), selected])
        end

        data = view_context.options_for_period_select(selected, nil,
                                                      show_future:     false,
                                                      hide_custom:     true,
                                                      no_html:         true,
                                                      disabled_values: ['all', 'is_not_null', 'is_null'],
        )

        label, items = data.first
        items.concat(other_items)

        if no_html
          data
        else
          view_context.grouped_options_for_select(data, selected)
        end
      end

      def field_for_render(**options)
        h = options[:view_context]

        h.select_tag("global_filter_#{options[:filter_id]}",
                     options_for_period_select(h, selected: options[:selected], no_html: false))
      end

    end

    # =========================================================================
    # DateFromToPeriod

    class DateFromToPeriodType < BaseType

      def name
        I18n.t('global_filters.label_date_from_to')
      end

      def type
        :date_from_to_period
      end

      def prepare_available_filters(view_context:)
        {
            name:                name,
            date_period_from_to: true,
            html5_dates:         !!EasySetting.value(:html5_dates)
        }
      end

      private

      def additional_class
        'global-filter--wide'
      end

      def field_for_render(**options)
        h        = options[:view_context]
        selected = options[:selected]

        h.date_field_tag("global_filter_#{options[:filter_id]}[from]", selected['from']) +
            h.calendar_for("global_filter_#{options[:filter_id]}_from") +
            h.date_field_tag("global_filter_#{options[:filter_id]}[to]", selected['to']) +
            h.calendar_for("global_filter_#{options[:filter_id]}_to")
      end

    end

    # =========================================================================
    # CountrySeCountrySelect

    class CountrySelectType < BaseType

      def name
        I18n.t(:label_country)
      end

      def type
        :country_select
      end

      def prepare_available_filters(view_context:)
        {
            name:          name,
            select_values: all_countries
        }
      end

      private

      def field_for_render(**options)
        h = options[:view_context]
        h.select_tag("global_filter_#{options[:filter_id]}", h.options_for_select(all_countries, options[:selected]))
      end

      def all_countries
        values = [["--- #{I18n.t(:label_in_modules)} ---", '']]
        values.concat ISO3166::Country.all_names_with_codes(I18n.locale)
      end

    end

    # =========================================================================
    # User

    class UserType < AutoCompleteType

      def name
        I18n.t(:label_user)
      end

      def type
        :user
      end

      private

      def autocomplete_action
        'internal_users'
      end

      def autocomplete_root
        'users'
      end

      def autocomplete_action_options
        super.merge!(include_peoples: 'me')
      end

      def find_entity(value)
        if value == 'me'
          EasyExtensions::GlobalFilters::Entity.new('me', "<< #{I18n.t(:label_me)} >>")
        else
          User.find_by(id: value)
        end
      end

    end

    # =========================================================================
    # Project

    class ProjectType < AutoCompleteType

      def name
        I18n.t(:label_project)
      end

      def type
        :project
      end

      private

      def autocomplete_action
        'visible_projects'
      end

      def autocomplete_root
        'projects'
      end

      def find_entity(value)
        Project.find_by(id: value)
      end

    end

    # =========================================================================
    # ListOptional

    class ListOptionalType < BaseType

      def name
        I18n.t(:label_list)
      end

      def type
        :list_optional
      end

      def prepare_available_filters(view_context:)
        {
            name:          name,
            manual_values: true
        }
      end

      def prepare_saved_filters!(options)
        options['selected_value'] = options['default_value']
      end

      private

      def field_for_render(**options)
        h = options[:view_context]

        values = options[:filter_options]['possible_values'].to_s.split("\n")
        values.each(&:chomp!)
        values.prepend(["--- #{I18n.t(:label_in_modules)} ---", ''])

        h.select_tag("global_filter_#{options[:filter_id]}", h.options_for_select(values, options[:selected]))
      end

    end

    # =========================================================================
    # Version

    class VersionType < AutoCompleteType

      def name
        I18n.t(:label_version)
      end

      def type
        :version
      end

      private

      def autocomplete_action
        'versions'
      end

      def autocomplete_root
        nil
      end

      def find_entity(value)
        Version.find_by(id: value)
      end

    end

    # =========================================================================
    # UserGroup

    class UserGroupType < AutoCompleteType

      def name
        I18n.t(:field_group)
      end

      def type
        :user_group
      end

      private

      def autocomplete_action
        'visible_user_groups'
      end

      def autocomplete_root
        nil
      end

      def find_entity(value)
        Group.find_by(id: value)
      end
    end

    class Entity

      def initialize(id, name)
        @id   = id
        @name = name
      end

      attr_reader :id, :name

      alias :to_s :name
    end

  end
end

EasyExtensions::GlobalFilters.tap do |f|
  f.register f::DatePeriodType
  f.register f::DateFromToPeriodType
  f.register f::CountrySelectType
  f.register f::UserType
  f.register f::ProjectType
  f.register f::ListOptionalType
  f.register f::VersionType
  f.register f::UserGroupType
end
