require 'set'

module EasyExtensions
  module Webdav
    class Resource
      include WEBrick::HTTPStatus
      include EasyExtensions::Webdav::Logger

      attr_reader :controller, :path

      LOCK_PROPERTY_NAMES = ['lockdiscovery', 'supportedlock']
      ACL_PROPERTY_NAMES  = ['current-user-privilege-set', 'supported-privilege-set']

      SUPPORTED_PRIVILEDGES = ['read', 'read-current-user-privilege-set', 'write-content', 'bind', 'unbind', 'unlock']

      def initialize(path, controller)
        @path       = path.gsub('//', '/')
        @controller = controller
      end

      def request
        controller.request
      end

      def response
        controller.response
      end

      def allowed?(method)
        allowed_methods.include?(method.to_s.upcase)
      end

      def header_dav
        [].freeze
      end

      def lockable?
        false
      end

      # Allow to set permission
      def controlled_access?
        false
      end

      def readable?
        false
      end

      # Creatable, Updatable, Deletable
      def writeable?
        false
      end

      def creatable?
        false
      end

      def updatable?
        false
      end

      def collection?
        false
      end

      def exist?
        collection? ? true : false
      end

      def children
        []
      end

      def descendants
        []
      end

      def property_names
        ['resourcetype'].freeze
      end

      def resourcetype
        return unless collection?

        render_xml_element do |xml|
          xml['d'].collection
        end
      end

      def get_property(name)
        if LOCK_PROPERTY_NAMES.include?(name) && !lockable?
          return NotFound.new
        end

        if ACL_PROPERTY_NAMES.include?(name) && !controlled_access?
          return NotFound.new
        end

        name = name.to_s.downcase.tr('-', '_')

        if respond_to?(name)
          __send__(name)
        else
          NotFound.new
        end
      end

      def render_xml_element
        Nokogiri::XML::Builder.new do |xml|
          xml.root(controller.class::NAMESPACES) do
            yield xml
          end
        end.doc.root.children
      end


      # Locking
      # =======================================================================
      #
      # +--------------------------+----------------+-------------------+
      # | Current State            | Shared Lock OK | Exclusive Lock OK |
      # +--------------------------+----------------+-------------------+
      # | None                     | True           | True              |
      # | Shared Lock              | True           | False             |
      # | Exclusive Lock           | False          | False             |
      # +--------------------------+----------------+-------------------+
      #
      def lock(options)
        # It is not done automatically
        lock_storage.remove_expired

        # Locks for current resource
        locks = lock_storage.active.where(path: options[:path]).to_a

        is_exclusive = locks.any?(&:exclusive?)
        is_shared    = locks.any?(&:shared?)

        # Check is resource is exclusive locked for more users
        # or locks are shared and exlusived at the same time
        # Should not happen !!!
        if (is_exclusive && locks.size >= 2) || (is_exclusive && is_shared)
          locks.each(&:delete)

          locks        = []
          is_exclusive = false
          is_shared    = false
        end

        # Current user lock
        my_lock = locks.detect(&:mine?)

        # Locked by other user
        if is_exclusive && my_lock.blank?
          raise Locked
        end

        # Resource is shared but user want exclusive lock
        if is_shared && options[:scope] == 'exclusive'
          raise Locked
        end

        if my_lock
          token = options[:token]

          if token && token == my_lock.token
            my_lock.set_timeout(options[:timeout])
          else
            raise Locked
            # raise PreconditionFailed
          end
        else
          my_lock = lock_storage.new(options)
        end

        unless my_lock.save
          raise BadRequest
        end

        my_lock
      end

      # Return HTTP status
      def unlock(token)
        lock = lock_storage.find_by_token(token)

        if lock.nil? || !lock.mine?
          Forbidden
        elsif lock.path != request.path
          Conflict
        else
          lock.destroy
          NoContent
        end
      end

      def render_lock(xml, lock_instance)
        xml['d'].activelock do
          xml['d'].lockscope { xml['d'].tag!(lock_instance.scope) }
          xml['d'].locktype { xml['d'].tag!(lock_instance.type) }
          xml['d'].depth('0')

          # if lock_instance.owner
          #   xml['d'].owner { xml['d'].href(lock_instance.owner) }
          # end

          xml['d'].owner do
            xml['d'].href(lock_instance.user.mail)
          end

          xml['d'].timeout_("Second-#{lock_instance.remaining_time.to_i}")
          xml['d'].locktoken do
            xml['d'].href(lock_instance.token)
          end
        end
      end

      def lockdiscovery
        locks = lock_storage.active.where(path: request.path)

        render_xml_element do |xml|
          locks.each do |lock_instance|
            render_lock(xml, lock_instance)
          end
        end
      end

      def supportedlock
        render_xml_element do |xml|
          xml['d'].lockentry do
            xml['d'].lockscope { xml['d'].exclusive }
            xml['d'].locktype { xml['d'].write }
          end

          xml['d'].lockentry do
            xml['d'].lockscope { xml['d'].shared }
            xml['d'].locktype { xml['d'].write }
          end
        end
      end


      # Access Control
      # =======================================================================
      #
      # These properties should not be returned by allprop request
      #
      # +---------------------------------+---------------------------------+
      # | METHOD                          | PRIVILEGES                      |
      # +---------------------------------+---------------------------------+
      # | GET                             | <D:read>                        |
      # | HEAD                            | <D:read>                        |
      # | OPTIONS                         | <D:read>                        |
      # | PUT (target exists)             | <D:write-content> on target     |
      # |                                 | resource                        |
      # | PUT (no target exists)          | <D:bind> on parent collection   |
      # |                                 | of target                       |
      # | PROPFIND                        | <D:read> (plus <D:read-acl> and |
      # |                                 | <D:read-current-user-privilege- |
      # |                                 | set> as needed)                 |
      # | DELETE                          | <D:unbind> on parent collection |
      # | LOCK (target exists)            | <D:write-content>               |
      # | LOCK (no target exists)         | <D:bind> on parent collection   |
      # | UNLOCK                          | <D:unlock>                      |
      # | REPORT                          | <D:read> (on all referenced     |
      # |                                 | resources)                      |
      # +---------------------------------+---------------------------------+
      #
      def supported_privilege_set
        render_xml_element do |xml|
          SUPPORTED_PRIVILEDGES.each do |name|
            xml['d'].send('supported-privilege') do
              xml['d'].privilege { xml['d'].send(name) }
            end
          end
        end
      end

      def current_user_privilege_set
        privileges = Set.new(['read-current-user-privilege-set'])

        if readable?
          privileges << 'read'
        end

        if writeable?
          privileges << 'bind'
          privileges << 'unbind'
          privileges << 'write-content'
        end

        if creatable?
          privileges << 'bind'
        end

        if updatable?
          privileges << 'write-content'
        end

        if lockable?
          privileges << 'bind'
          privileges << 'unlock'
          privileges << 'write-content'
        end

        render_xml_element do |xml|
          privileges.each do |name|
            xml['d'].privilege { xml['d'].send(name) }
          end
        end
      end

      private

      def lock_storage
        EasyExtensions::Webdav::Lock
      end

    end
  end
end
