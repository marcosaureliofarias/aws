class MigrateEasyContactTypes < EasyExtensions::EasyDataMigration

  def up
    # There are 2 defaults
    EasyContactType.update_all(is_default: false)
    last = EasyContactType.last
    last && last.update_columns(is_default: true)

    # Set new type of icon
    EasyContactType.all.each do |type|
      case type.internal_name
      when 'account'
        type_name = 'Account'
        icon_path = 'icon-globe'
        core_fields = ['firstname']

      when 'corporate'
        type_name = 'Company'
        icon_path = 'icon-group'
        core_fields = ['firstname']

      when 'personal'
        type_name = 'Personal'
        icon_path = 'icon-user'
        core_fields = ['firstname', 'lastname']

      else
        type_name = nil
        icon_path = nil
        core_fields = nil
      end

      type.type_name = type_name if type_name
      type.icon_path = icon_path if icon_path
      type.core_fields = core_fields if core_fields
      type.save
    end
  end

  def down
    # Set old type of icon
    EasyContactType.all.each do |type|
      case type.internal_name
      when 'account'   then type.update_columns(icon_path: nil)
      when 'corporate' then type.update_columns(icon_path: 'group.png')
      when 'personal'  then type.update_columns(icon_path: 'user.png')
      end
    end
  end

end
