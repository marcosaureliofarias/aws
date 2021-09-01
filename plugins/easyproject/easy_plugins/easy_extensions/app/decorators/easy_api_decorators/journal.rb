module EasyApiDecorators
  class Journal < EasyApiEntity

    include EasyJournalHelper

    def build_api!(api)
      api.journal id: @entity.id do
        api.user(id: @entity.user_id, name: @entity.user.name) unless @entity.user.nil?
        api.notes @entity.notes
        api.created_on @entity.created_on
        api.private_notes @entity.private_notes
        api.array :details do
          @entity.visible_details.each do |detail|
            api.detail property: detail.property, name: detail.prop_key do
              api.old_value detail.old_value
              api.new_value detail.value
            end
          end
        end
      end
      api
    end

    def self.entity_class
      ::Journal
    end
  end
end
