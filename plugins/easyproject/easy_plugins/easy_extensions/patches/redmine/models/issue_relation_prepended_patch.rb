module EasyPatch
  module IssueRelationPrependedPatch

    # Problem: http://www.redmine.org/issues/14846
    #   Redmine is counting delay as working days
    #   We don't want that
    def successor_soonest_start
      if (self.class::TYPE_PRECEDES == relation_type) && delay && issue_from &&
          (issue_from.start_date || issue_from.due_date)
        (issue_from.due_date || issue_from.start_date) + 1 + delay
      end
    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'IssueRelation', 'EasyPatch::IssueRelationPrependedPatch', prepend: true
