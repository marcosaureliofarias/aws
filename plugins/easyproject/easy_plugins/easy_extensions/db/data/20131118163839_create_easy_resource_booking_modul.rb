class CreateEasyResourceBookingModul < ActiveRecord::Migration[4.2]
  def up
    unless EasyPage.where(page_name: 'easy-resource-booking-module').exists?
      page           = EasyPage.find_by(page_name: 'my-page').dup
      page.page_name = 'easy-resource-booking-module'
      page.save

      EasySetting.create(name: :show_easy_resource_booking, value: true)
    end
  end

  def down
    EasyPage.where(page_name: 'easy-resource-booking-module').destroy_all
    EasySetting.where(name: 'show_easy_resource_booking').destroy_all
  end
end
