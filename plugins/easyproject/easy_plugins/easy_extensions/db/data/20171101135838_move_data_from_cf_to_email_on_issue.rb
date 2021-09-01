class MoveDataFromCfToEmailOnIssue < EasyExtensions::EasyDataMigration
  def up
    cf = IssueCustomField.find_by(internal_name: 'external_mails')
    if cf
      case ActiveRecord::Base.connection.adapter_name.downcase
      when /mysql/
        Issue.connection.execute("UPDATE #{Issue.table_name} i
                                    INNER JOIN #{CustomValue.table_name} c
                                    ON c.custom_field_id = #{cf.id} AND c.value != '' AND c.value IS NOT NULL AND i.id = c.customized_id
                                    SET i.easy_email_to = c.value"
        )
      when /postgresql/
        Issue.connection.execute("UPDATE #{Issue.table_name} i
                                    SET easy_email_to = c.value
                                    FROM #{CustomValue.table_name} c
                                    WHERE c.custom_field_id = #{cf.id} AND c.value != '' AND c.value IS NOT NULL AND i.id = c.customized_id"
        )
      end

      trackers = Tracker.where("NOT EXISTS (SELECT tracker_id from custom_fields_trackers where trackers.id = custom_fields_trackers.tracker_id and custom_fields_trackers.custom_field_id = #{cf.id})")
      trackers.each do |tracker|
        core_fields         = tracker.core_fields - ['easy_email_to', 'easy_email_cc']
        tracker.core_fields = core_fields
        tracker.save
      end

      cf.destroy
    end
  end

  def down
  end
end
