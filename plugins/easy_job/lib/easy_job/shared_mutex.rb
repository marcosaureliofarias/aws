module EasyJob
  ##
  # Mutex for cross process/threads synchronization.
  # Database is used for this so be careful for timeout.
  # Critical section should be as short as possible.
  #
  class SharedMutex

    class << self
      def ensure_lock(name)
        EasySetting.find_or_create_by!(name: sync_token_name(name))
      end

      def sync_token_name(name)
        "EasyJob_SharedMutex_#{name}"
      end
    end

    def initialize(name)
      @name = name
    end

    def sync_token_name
      self.class.sync_token_name(@name)
    end

    def synchronize
      saved_token = EasySetting.find_or_create_by!(name: sync_token_name)
      saved_token.with_lock do
        yield
        saved_token.value = Time.now
        saved_token.save
      end
    end

  end
end
