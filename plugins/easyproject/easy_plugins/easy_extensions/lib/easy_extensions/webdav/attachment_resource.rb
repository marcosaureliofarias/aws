module EasyExtensions
  module Webdav
    class AttachmentResource < Resource

      def property_names
        ['getetag', 'getcontenttype', 'getcontentlength', 'getlastmodified', 'displayname', 'resourcetype', 'creationdate', *LOCK_PROPERTY_NAMES].freeze
      end

      def allowed_methods
        ['OPTIONS', 'HEAD', 'GET', 'PUT', 'LOCK', 'UNLOCK', 'PROPFIND'].freeze
      end

      def collection?
        false
      end

      def lockable?
        true
      end

      def exist?
        !!entity
      end

      def getetag
        entity.digest
      end

      def getcontenttype
        entity.content_type
      end

      def getcontentlength
        entity.filesize
      end

      def getlastmodified
        entity.current_version.updated_at.httpdate
      end

      def creationdate
        entity.current_version.created_on.iso8601
      end

      def displayname
        entity.filename
      end

      def allowed_for_read?
        User.current.admin? || entity.visible?
      end

      def allowed_for_edit?
        User.current.admin? || entity.editable?
      end

      def check_read_permission
        raise Forbidden unless allowed_for_read?
      end

      def check_write_permission
        raise Forbidden unless allowed_for_edit?
      end

      def entity
        return @entity if @entity

        id = path.match(/attachment\/(\d+).*/).try(:[], 1)

        if id.nil?
          raise NotFound
        end

        begin
          @entity = Attachment.find(id)
        rescue ActiveRecord::RecordNotFound
          raise NotFound
        end
      end


      # HTTP Requests
      # =======================================================================

      # HTTP GET request.
      #
      # Write the content of the resource to the response.body.
      def get
        check_read_permission

        entity.mark_as_read(User.current)

        response['Content-Security-Policy'] = "default-src 'self'"
        response['Content-Type'] = getcontenttype
        response['Content-Length'] = getcontentlength
        response['Content-Disposition'] = "inline; filename=#{displayname}"
        response.body                   = File.open(entity.diskfile)
      end

      # HTTP PUT request.
      #
      # Save the content of the request.body.
      def put
        check_write_permission

        # request.body can be StringIO, Rack::Lint::InputWrapper, ...
        if request.body.respond_to?(:read)
          body = request.body.read
        else
          body = request.body
        end

        attachment             = Attachment.new(file: body)
        attachment.author      = User.current
        attachment.filename    = entity.filename
        attachment.description = attachment.filename if attachment.description_required?
        attachment.save

        attachments = [{
                           'token'                            => attachment.token,
                           'custom_version_for_attachment_id' => entity.id,
                           'description'                      => entity.description
                       }]

        # Save it
        Attachment.attach_files(entity.container, attachments)
      end

    end
  end
end
