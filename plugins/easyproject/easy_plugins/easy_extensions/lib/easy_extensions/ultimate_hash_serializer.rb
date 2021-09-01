# frozen_string_literal: true

require 'yaml'

module EasyExtensions
  ##
  # This class should be used as ActiveRecord serializator
  # for columns where Hash is saved but the data could
  # also come from params.
  #
  #   EasyExtensions::UltimateHashSerializer.dump({ 'test' => 1 })
  #   EasyExtensions::UltimateHashSerializer.dump(ActionController::Parameters.new({ 'test' => 1 }))
  #   # => "---\ntest: 1\n"
  #
  #   EasyExtensions::UltimateHashSerializer.load("---\ntest: 1\n")
  #   # => { 'test' => 1 }
  #
  # @see ActiveRecord::Coders::YAMLColumn
  #
  class UltimateHashSerializer

    def self.dump(object)
      return if object.nil?

      object = ensure_hash!(object)
      YAML.dump(object)
    end

    def self.load(yaml)
      if yaml.nil?
        return {}
      end

      if !yaml.is_a?(String) || !yaml.start_with?('---')
        return yaml
      end

      object = YAML.load(yaml)
      object = ensure_hash!(object)
      object
    end

    def self.ensure_hash!(object)
      case object
      when ActionController::Parameters
        object.to_unsafe_h
      when Hash
        object
      when NilClass
        object
      else
        raise ActiveRecord::SerializationTypeMismatch, "Expected Hash but got a #{object.class}"
      end
    end

  end
end
