require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class UserImportable < Importable

    def initialize(data)
      @klass = User
      super
    end

    def mappable?
      true
    end

    def custom_mapping(map)
      map['principal'] ||= {}
      map['principal'].merge!(map['user'])
    end

    private

    def update_attribute(record, name, value, map, xml)
      case name
      when 'easy_lesser_admin_permissions'
        record.easy_lesser_admin_permissions = value.blank? ? [] : Array(value)
      when 'easy_online_status'
        record.easy_online_status = Integer(value) rescue value # '0', 'offline'
      else
        super
      end
    end

    def existing_entities
      klass.all.sort_by(&:name)
    end

    def entities_for_mapping
      users = []
      @xml.xpath('//easy_xml_data/users/*').each do |user_xml|
        login = user_xml.xpath('login').text
        name  = user_xml.xpath('firstname').text + ' ' + user_xml.xpath('lastname').text
        mail  = user_xml.xpath('mail').text
        status = user_xml.xpath('status').text.to_i
        if (login.blank? && mail.blank?) || status == AnonymousUser::STATUS_ANONYMOUS
          match = AnonymousUser.first
        else
          match = User.joins(:email_address).where(["login = ? or #{EmailAddress.quoted_table_name}.address = ?", login, mail]).first
        end
        if match.blank? && allowed_to_create_entities?
          # TODO: we should warn the admin about such users because their passwords must be updated at least
          match = User.create!(login:     login,
                               firstname: user_xml.xpath('firstname').text,
                               lastname:  user_xml.xpath('lastname').text,
                               mail:      mail
                              )
        end
        users << { id: user_xml.xpath('id').text, login: login, name: name, match: match ? match.id : '' }
      end
      users
    end

    def after_record_save(user, xml, map)
      from_id                   = xml.xpath('id').text
      map['principal'][from_id] = user.id if from_id.present?
    end

  end
end
