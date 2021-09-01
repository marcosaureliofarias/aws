module Ryspec::Test
  module Settings

    def with_settings(options, &block)
      saved_settings = options.each_with_object({}) do |(key, value), memo|
        memo[key] = case Setting[key]
                    when Symbol, false, true, nil
                      Setting[key]
                    else
                      Setting[key].dup
                    end
      end
      options.each {|key, value| Setting[key] = value }
      Setting.clear_cache
      yield
    ensure
      saved_settings.each {|key, value| Setting[key] = value }
      Setting.clear_cache
    end

    def with_easy_settings(options, project=nil, &block)
      saved_settings = options.each_with_object({}) do |(key, value), memo|
        old_value = EasySetting.value(key, project)
        memo[key] = case old_value
                    when Symbol, Integer, false, true, nil
                      old_value
                    else
                      old_value.dup
                    end
      end

      options.each do |key, value|
        setting = EasySetting.find_or_initialize_by(name: key, project_id: project&.id)
        setting.value = value
        setting.save!
      end

      yield
    ensure
      saved_settings.each do |key, value|
        set = EasySetting.find_by(name: key, project_id: project&.id)
        set.value = value
        set.save!
      end
    end

  end
end
