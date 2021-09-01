module EasyAlerts
  module Rules

    class Base
      include ActiveModel::Validations

      attr_accessor :alert_name
      attr_accessor :active_projects_only

      def initialize_from_alert(alert)
        @active_projects_only = alert.active_projects_only
        initialize_from_params(alert.rule_settings)
      end

      def initialize_from_params(params)
        initialize_properties(params)
      end

      def validate_alert(alert)
        initialize_from_alert(alert)

        valid?

        errors.each do |attr,msg|
          alert.errors.add attr, msg
        end

        validate_if_issue_required_for_alert alert
      end

      def serialize_settings_to_hash(params)
        {}
      end

      # Abstracts methods
      def find_items(alerts, user=User.current)
        raise NotImplementedError, 'You have ovverride find_items!'
      end

      def expires_at(alert)
        nil
      end

      def mailer_template_name(alert)
        nil
      end

      def self.registered_in_plugin
        klass_path = instance_method(:find_items).source_location.first
        core_path = EasyExtensions::EASYPROJECT_EASY_PLUGINS_DIR

        (klass_path.split('/') - core_path.split('/')).first
      end

      def issue_provided?
        false # must be overriden for issue related rules
      end

      def validate_if_issue_required_for_alert alert
        if alert.issue_required? && !issue_provided?
          alert.errors.add :mail_for, I18n.t('easy_alert.issue_providing_rule_required_error')
        end
      end

      protected

      def initialize_properties(params)
      end
    end

  end
end
