module EasyCrm
  class RecalculateEasyContactFields < EasyActiveJob
    queue_as :recalculate_custom_fields

    def perform(easy_crm_case)
      EasyRakeTaskComputedFromQuery.recalculate_entity(easy_crm_case.main_easy_contact) if easy_crm_case.main_easy_contact
    end

  end
end
