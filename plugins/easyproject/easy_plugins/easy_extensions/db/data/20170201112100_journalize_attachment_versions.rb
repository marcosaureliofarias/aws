class JournalizeAttachmentVersions < EasyExtensions::EasyDataMigration
  def up
    journalized_types = Journal.distinct.pluck(:journalized_type).select { |type| type.safe_constantize }

    JournalDetail.transaction do
      JournalDetail.eager_load(:journal).preload(:journal => { :journalized => { :attachments => :versions } }).where(:property => 'attachment', :journals => { :journalized_type => journalized_types }).where.not(:value => '').find_each(:batch_size => 400) do |detail|
        prop_key_id = detail.prop_key.to_i
        next if detail.journal.nil? ||
            detail.journal.journalized.nil? ||
            !detail.journal.journalized.respond_to?(:attachments) ||
            detail.journal.journalized.attachments.map(&:id).include?(prop_key_id)

        if (detail.journal.journalized.attachments.flat_map { |a| a.version_ids }).include?(prop_key_id)
          detail.update_column(:property, 'attachment_version')
        end
      end
    end
  end

  def down
  end
end