module EasyExtensions
  module EasyJobs
    class UserReadableTask < EasyJob::Task
      def perform(entity_id, entity_type, user_id)
        EasyUserReadEntity.create(:read_on => Time.now, :entity_id => entity_id, :entity_type => entity_type, :user_id => user_id)
      rescue ActiveRecord::RecordNotUnique
      end
    end
  end
end