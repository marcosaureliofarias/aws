# To touch this constant because easy_extensions/lib is in autoload
EasyExtensions::GlobalFilters

module EasyExtensions
  class GlobalFilters
    class SprintType < AutoCompleteType

      def name
        I18n.t(:field_easy_sprint)
      end

      def type
        :sprint
      end

      private

        def autocomplete_action
          'sprints'
        end

        def autocomplete_root
          'easy_sprints'
        end

        def find_entity(value)
          EasySprint.find_by(id: value)
        end

    end
  end
end

EasyExtensions::GlobalFilters.tap do |f|
  f.register f::SprintType
end
