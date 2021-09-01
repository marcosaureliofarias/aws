class MigrateEasyIcons < EasyExtensions::EasyDataMigration
  include EasyIconsHelper

  def up
    [Tracker, Enumeration].each do |klass|
      klass.where.not(:easy_icon => nil).each do |entity|
        entity.update_column(:easy_icon, easy_icon_char_to_name(entity.easy_icon))
      end
    end
  end

  def down
  end
end