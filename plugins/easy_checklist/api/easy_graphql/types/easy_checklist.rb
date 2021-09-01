# frozen_string_literal: true

module EasyGraphql
  module Types
    class EasyChecklist < Base

      field :id, ID, null: false
      field :name, String, null: true
      field :type, String, null: true
      field :author, Types::User, null: false
      field :easy_checklist_items, [Types::EasyChecklistItem], null: true
      field :editable, Boolean, null: false, method: :can_edit?
      field :deletable, Boolean, null: false, method: :can_delete?

    end
  end
end
