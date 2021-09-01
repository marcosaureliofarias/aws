class InitializePositionOnEasyCrmCaseItems < ActiveRecord::Migration[4.2]
  def up
    items_with_position = EasyCrmCaseItem.pluck(:easy_crm_case_id, :id).group_by(&:first)
    EasyCrmCaseItem.transaction do
      items_with_position.each do |_, easy_crm_case_item_ids|
        easy_crm_case_item_ids.map(&:second).each_with_index do |id, index|
          EasyCrmCaseItem.where(id: id).update_all(position: index + 1)
        end
      end
    end
  end

  def down
    EasyCrmCaseItem.update_all(:position => nil)
  end
end
