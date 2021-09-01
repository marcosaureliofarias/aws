class AddMobileDefaultToEasyTabs < ActiveRecord::Migration[4.2]

  def up
    add_column(:easy_page_user_tabs, :mobile_default, :boolean, default: false)
    add_column(:easy_page_template_tabs, :mobile_default, :boolean, default: false)
  end

  def down
    remove_column(:easy_page_user_tabs, :mobile_default)
    remove_column(:easy_page_template_tabs, :mobile_default)
  end

end
