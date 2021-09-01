# frozen_string_literal: true

module EasyGraphql
  module Types
    class IssueRelation < Base

      field :id, ID, null: false
      field :issue_to, Types::Issue, null: true
      field :issue_from, Types::Issue, null: true
      field :relation_type, String, null: true
      field :relation_name, String, null: true do
        argument :issue_id, ID, 'Current issue id', required: true
      end
      field :delay, Integer, null: true
      field :other_issue, Types::Issue, null: true do
        argument :issue_id, ID, 'Current issue id', required: true
      end

      def other_issue(issue_id:)
        other_issue = object.other_issue(OpenStruct.new(id: issue_id.to_i))
        other_issue if other_issue&.visible?
      end

      def issue_to
        issue_to = object.issue_to
        issue_to if issue_to&.visible?
      end

      def issue_from
        issue_from = object.issue_from
        issue_from if issue_from&.visible?
      end

      def relation_name(issue_id:)
        issue = issue_id == object.issue_to_id.to_s ? object.issue_to : object.issue_from
        object.to_s(issue)
      end
    end
  end
end
