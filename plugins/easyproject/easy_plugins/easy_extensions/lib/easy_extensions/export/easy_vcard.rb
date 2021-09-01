module EasyExtensions
  module Export
    require 'vcard'
    class EasyVcard

      ATTRIBUTES = [:degree, :firstname, :lastname, :mail, :phone, :organization, :city, :street, :postal_code, :country, :updated_at]

      attr_accessor *ATTRIBUTES
      attr_writer :entity

      def initialize(*args)
        @options                = args.extract_options!
        @options[:allow_avatar] = true if @options[:allow_avatar].nil?
        @entity                 = args.first
      end

      def attributes=(args)
        args.each do |key, value|
          send("#{key}=", value)
        end
      end

      def attributes
        ATTRIBUTES.inject({}) do |mem, var|
          mem[var] = send(var)
          mem
        end
      end

      alias_method :title, :degree
      alias_method :prefix, :degree

      def to_vcard(options = {})
        @options.merge!(options)
        Vcard::Vcard::Maker.make2 do |maker|
          location = 'work'

          maker.add_name do |name|
            if title.present?
              name.prefix = title
            end
            name.given  = firstname
            name.family = lastname.to_s
          end

          maker.org = organization if organization

          if city.present? || street.present? || postal_code.present? || country.present?
            maker.add_addr do |addr|
              addr.preferred = true
              addr.location  = location

              addr.street     = street.to_s
              addr.postalcode = postal_code.to_s
              addr.locality   = city.to_s
              addr.country    = country.to_s
            end
          end

          if phone.present?
            maker.add_tel(phone) do |tel|
              tel.preferred  = true
              tel.location   = location
              tel.capability = 'voice'
            end
          end

          if mail.present?
            maker.add_email(mail) do |mail|
              mail.preferred = true
              mail.location  = location
            end
          end

          if @entity.respond_to?(:easy_avatar) && @options[:allow_avatar]
            if avatar = @entity.easy_avatar
              if @options[:with_avatar]
                img_path = avatar.image.path(:medium)
                if File.exists?(img_path)
                  maker.add_photo do |photo|
                    photo.image = File.read(img_path)
                    photo.type  = avatar.image.content_type.split('/').last.upcase
                  end
                end
              else
                maker.add_photo do |photo|
                  photo.link = "#{Setting.protocol}://#{Setting.host_name}" + avatar.image.url(:medium)
                  photo.type = avatar.image.content_type.split('/').last.upcase
                end
              end
            end
          end

          uid = nil
          if @entity.respond_to?(:uid)
            uid = @entity.uid
          elsif @entity.respond_to?(:guid)
            uid = @entity.guid
          end
          maker.add_field Vcard::DirectoryInfo::Field.create('UID', uid) if uid
          maker.add_field Vcard::DirectoryInfo::Field.create('REV', updated_at.iso8601) if updated_at.present?
        end
      end

      def self.associated_query_class
        EasyExtensions::Export::EasyVcard::DummyEasyQuery
      end

      class DummyEasyQuery

        def available_columns
          ATTRIBUTES.map { |a| EasyQueryColumn.new(a, :caption => "easy_vcard_attributes.#{a.to_s}") }
        end

      end
    end
  end
end
