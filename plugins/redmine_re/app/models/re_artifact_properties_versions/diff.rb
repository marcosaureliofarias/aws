module ReArtifactPropertiesVersions
  module Diff
    extend ActiveSupport::Concern

    included do
    end

    class_methods do
      Diff = Struct.new(:object, :changes) do
        delegate :id, :timestamp_to_s, :version, :user_id, :user_name, to: :object, allow_nil: true
      end

      def diff_hash(object = nil)
        Hash[self::STORE_ATTRIBUTES.map { |key| [key, object.present? ? object.send(key) : nil] }]
      end

      def diff_change_type(source, target)
        source, target = source.presence, target.presence

        if source.nil? && target.present?
          :added
        elsif source.present? && target.nil?
          :deleted
        elsif source.present? && target.present?
          :changed
        end
      end

      def diff_collection(collection)
        initial_hash = diff_hash

        collection.order(created_at: :asc).map do |object|
          object_hash = diff_hash(object)

          diff = Diff.new(object, [])

          initial_hash.each do |key, value|
            new_value = object_hash[key]
            next if new_value == value

            value = case diff_change_type(value, new_value)
                    when :added
                      I18n.t(:re_artifact_properties_diff_added, key: key, new_value: new_value)
                    when :deleted
                      I18n.t(:re_artifact_properties_diff_deleted, key: key, value: value)
                    when :changed
                      I18n.t(:re_artifact_properties_diff_changed, key: key, value: value, new_value: new_value)
                    end

            diff.changes << value if value
          end

          initial_hash = object_hash

          diff
        end.reverse
      end
    end
  end
end