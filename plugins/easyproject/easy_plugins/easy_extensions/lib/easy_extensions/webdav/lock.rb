module EasyExtensions
  module Webdav
    ##
    # EasyExtensions::Webdav::Lock
    #
    # - only depth 0 is supported
    #
    # == Scope:
    #
    # Exclusive::
    #   Only one user have rights. There is risk if user won't release the lock
    #   or editor crash.
    #
    # Shared::
    #   To tell to others that I may edit a document.
    #
    class Lock < ActiveRecord::Base

      self.table_name         = 'easy_webdav_locks'
      self.inheritance_column = nil

      belongs_to :user

      # 24 hours
      MAX_TIMEOUT = 86_400

      scope :active, lambda { where(['expired_at > ?', Time.now]) }

      validates_presence_of :scope, :type

      def self.remove_expired
        where(['expired_at <= ?', Time.now]).delete_all
      end

      def initialize(options)
        super()

        self.scope   = options[:scope]
        self.type    = options[:type]
        self.path    = options[:path]
        self.owner   = options[:owner]
        self.user_id = User.current.id
        self.token   = "opaquelocktoken:#{EasyUtils::UUID.generate}"

        set_timeout(options[:timeout])
      end

      def set_timeout(timeout)
        self.expired_at = Time.now + [timeout.to_i, MAX_TIMEOUT].min.seconds
      end

      def mine?
        user_id == User.current.id
      end

      def exclusive?
        scope == 'exclusive'
      end

      def shared?
        scope == 'shared'
      end

      def remaining_time
        expired_at - Time.now
      end

    end
  end
end
