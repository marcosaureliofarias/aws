module EasyContacts
  module Carddav
    class UserResource < VcardResource

      def allowed_methods
        ['OPTIONS', 'HEAD', 'GET', 'PROPFIND', 'REPORT'].freeze
      end

      def getetag
        "\"#{entity.updated_on.to_i}\""
      end

      def address_data
        return @address_data if @address_data

        vcard_generator = EasyExtensions::EasyEntityAttributeMappings::VcardMapper.new(entity, EasyExtensions::Export::EasyVcard).map_entity

        if vcard_generator
          @address_data = Redmine::CodesetUtil.safe_from_utf8(vcard_generator.to_vcard, 'UTF-8')
        else
          raise NotFound
        end
      end

      def find_entity
        id = path.split('/').last
        id.sub!(/\.vcf\Z/, '')

        User.visible.where(id: id).first
      end

    end
  end
end
