# frozen_string_literal: true

module EasyGraphql
  module Mutations
    class Base < GraphQL::Schema::Mutation

      # Called before arguments are prepared.
      #
      # override this to check your global permissions
      def ready?(**args)
        true
      end

      # Called after arguments are loaded, but before resolving.
      #
      # override this to check entity presence
      # override this to check entity permissions
      # call super to get the default checks
      def authorized?(**args)
        true
      end

      # return false when not founded
      # in order to skip GraphQL::LoadApplicationObjectFailedError
      #
      # render in authorized #response_record_not_found
      def object_from_id(type, id, context)
        entity_class = type.entity_class&.safe_constantize
        return false unless entity_class

        self.entity = get_entity(entity_class, id) || false
      end

      def get_entity(entity_class, id)
        if entity_class.respond_to?(:visible)
          entity_class.visible.find_by(id: id)
        else
          entity_class.find_by(id: id)
        end
      end

      # historical meaning
      # to be removed in 2.0.0
      def find_entity(entity_id, entity_type)
        entity_class = begin; entity_type.constantize; rescue; nil; end
        return if entity_class.nil?

        @entity = if entity_class.respond_to?(:visible)
                    entity_class.visible.find_by(id: entity_id)
                  else
                    entity_class.find_by(id: entity_id)
                  end
      end

      # Set entity to use responses
      attr_accessor :entity

      def response_record_not_found
        errors = [ { attribute: 'base', full_messages: [I18n.t('easy_graphql.record_not_found')] } ]
        { errors: errors }
      end

      def response_record_not_authorized
        errors = [ { attribute: 'base', full_messages: [I18n.t('easy_graphql.not_authorized')] } ]
        { errors: errors }
      end

      def response_errors
        { errors: prepare_errors }
      end

      def response_entity
        entity_key = entity.present? ? entity.class.model_name.element : nil
        entity_key ? { "#{entity_key}" => entity } : nil
      end

      def response_all
        response_errors.merge(response_entity)
      end

      # TODO refactor
      def prepare_errors
        return [] if !entity || !entity.errors.any?

        errors = []
        entity.errors.to_hash(true).each do |att, mess|
          next if att == :base

          errors << { attribute: att, full_messages: mess.uniq }
        end
        entity.errors.details[:base].each_with_object(Hash.new {|h,k| h[k] = []}) do |err, hash|
          if err[:attributes].present?
            err[:attributes].each do |att|
              hash[att] << err[:error]
            end
          else
            hash[:base] << err[:error]
          end
        end.each do |att, mess|
          errors << { attribute: att, full_messages: mess.uniq }
        end
        errors
      end

    end
  end
end
