class EasyRakeTaskRepeatingEntities < EasyRakeTask

  def execute

    log_info 'RepeatingEntitiesTask excuting...'
    total    = 0
    all_done = true

    EasyExtensions::EntityRepeater.all_repeaters.each do |repeater|
      log_info "executing #{repeater.class.name}..."

      count        = 0
      entity_count = 0

      repeater.entities_to_repeat.each do |entity|

        next if repeater.skip_entity?(entity)
        next unless entity.easy_repeat_settings['repeat_hour'].to_i <= Time.now.hour #repeat_hour
        next unless entity.should_repeat?

        entity_count += 1
        begin
          count += 1 if entity.repeat
        rescue => e
          self.class.logger.error "RepeatingEntitiesTask failed on #{repeater} => #{entity.class.name}##{entity.id} with #{e.message}"
          all_done = false
        end
      end
      total += count

      log_info "#{repeater.class.name} repeated #{count}/#{entity_count} entities"
    end

    log_info "RepeatingEntitiesTask done. #{total} entities was created."

    [all_done, total]
  end

end
