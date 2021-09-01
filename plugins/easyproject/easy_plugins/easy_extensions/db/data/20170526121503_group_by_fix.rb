class GroupByFix < EasyExtensions::EasyDataMigration
  def up
    EasyQuery.transaction do
      EasyQuery.find_each(:batch_size => 200) do |q|
        value = begin
          q.read_attribute(:group_by)
        rescue StandardError
          q.read_attribute_before_type_cast(:group_by)
        end
        if value.is_a?(Array)
          value.uniq!
          value.reject!(&:blank?)
        end
        q.class.base_class.where(q.class.primary_key => q.send(q.class.primary_key)).update_all(:group_by => value.presence)
      end
    end
  end

  def down
  end
end
