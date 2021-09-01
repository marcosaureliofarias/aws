# frozen_string_literal: true

module EasyGraphql
  module Types
    class Mutation < Base
      field :easy_short_url_create, mutation: EasyGraphql::Mutations::EasyShortUrlCreate
      field :mark_as_read, mutation: Mutations::MarkAsRead
      field :journal_change, mutation: Mutations::JournalNotes
      field :issue_validator, mutation: Mutations::IssueValidator
      field :custom_value_change, mutation: Mutations::CustomValueChange
    end
  end
end
