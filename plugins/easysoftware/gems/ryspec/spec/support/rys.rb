module Ryspec::Test
  module Rys

    def with_features(features, &block)
      original_statuses = []

      features.each do |name, active|
        rys_feature = ::Rys::Feature.all_features[name.to_s]
        if !rys_feature
          raise ArgumentError, "Feature '#{name}' is not registered so cannot be changed"
        end

        loop {
          original_statuses << { name: name, block_condition: rys_feature.block_condition }
          rys_feature.block_condition = proc { !!active }

          rys_feature = rys_feature.parent
          break if rys_feature.root?
        }
      end

      yield
    ensure
      original_statuses.each do |original_status|
        rys_feature = ::Rys::Feature.all_features[original_status[:name]]
        rys_feature.block_condition = original_status[:block_condition]
      end
    end

    def when_rys_activated(feature)
      pending "Feature deactivated" unless ::Rys::Feature.active?(feature)
      yield if block_given?
    end

  end
end
