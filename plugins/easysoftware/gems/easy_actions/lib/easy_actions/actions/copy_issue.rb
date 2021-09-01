module EasyActions
  module Actions
    class CopyIssue < ::EasyActions::Actions::Base

      attr_accessor :issue_id

      validates :issue_id

    end
  end
end
