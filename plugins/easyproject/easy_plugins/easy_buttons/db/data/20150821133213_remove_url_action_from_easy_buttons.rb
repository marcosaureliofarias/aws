class RemoveUrlActionFromEasyButtons < ActiveRecord::Migration[4.2]
  def up
    EasyButton.find_each(batch_size: 50) do |button|

      if button.actions
        case button.actions[:type]
        when 'query'
          button.update_column(:actions, button.actions[:query])
        when 'url'
          button.update_column(:actions, {})
        else
          # shoudl be ok
        end
      end

    end
  end
end
