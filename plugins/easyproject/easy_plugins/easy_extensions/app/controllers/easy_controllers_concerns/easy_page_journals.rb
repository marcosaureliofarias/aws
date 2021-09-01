module EasyControllersConcerns
  module EasyPageJournals
    extend ActiveSupport::Concern

    included do
      after_action :create_easy_page_journal, if: -> { callback_condition }
    end

    private

    def callback_condition
      journalized_actions.include?(action_name) && @page.present? && @page.page_scope.blank?
    end

    def journalized_actions
      self.class::JOURNALIZED_ACTIONS
    end

    def extract_additional_data
      case action_name
        # EasyPageLayoutController
      when 'add_module'
        @available_module.module_definition.translated_name
      when 'clone_module', 'remove_module'
        @zone_module.module_definition.translated_name
      when 'remove_tab'
        @tab.name
        # MyController
      when 'save_my_page_module_view'
        @epzm.module_definition.translated_name
      end
    end

    def create_easy_page_journal
      notes = l("easy_pages.journalized_actions.#{action_name}")
      notes << " - #{extract_additional_data}" if extract_additional_data
      @page.init_journal(User.current, notes).save
    end

  end
end
