class EasyAlertMaintenanceJob < EasyActiveJob
  queue_as :default

  def perform
    AlertReport.connection.execute("DELETE FROM #{AlertReport.quoted_table_name} WHERE NOT EXISTS (SELECT #{Alert.quoted_table_name}.id FROM #{Alert.quoted_table_name} WHERE #{Alert.quoted_table_name}.id = #{AlertReport.quoted_table_name}.alert_id)")

    started_at = Time.now
    log_info '    Alert.generate_reports_all...'
    begin
      Alert.generate_reports_all
    rescue StandardError => ex
      raise JobFailed.new(ex)
    end
    log_info "    Alert.generate_reports_all (#{Time.now - started_at}s)"

    started_at = Time.now
    log_info '    Alert.generate_reports_all...'
    begin
      AlertReport.delete_all_not_sent_reports
    rescue StandardError => ex
      raise JobFailed.new(ex)
    end
    log_info "    Alert.generate_reports_all (#{Time.now - started_at}s)"

    started_at = Time.now
    log_info '    AlertMailer.send_not_emailed_reports...'
    begin
      AlertMailer.send_not_emailed_reports
    rescue StandardError => ex
      raise JobFailed.new(ex)
    end
    log_info "    AlertMailer.send_not_emailed_reports (#{Time.now - started_at}s)"

    started_at = Time.now
    log_info '    AlertReport.purge_all(31)...'
    begin
      AlertReport.purge_all(31)
    rescue StandardError => ex
      raise JobFailed.new(ex)
    end
    log_info "    AlertReport.purge_all(31)... (#{Time.now - started_at}s)"

    return true
  end

  def registered_in_plugin
    :easy_alerts
  end

end
