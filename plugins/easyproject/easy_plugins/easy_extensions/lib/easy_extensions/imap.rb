require 'net/imap'

module EasyExtensions
  class IMAP

    def self.test_connection(imap_options = {})
      EasyExtensions::IMAP.new(imap_options).test_connection
    end

    def self.available_folders(imap_options = {}, options = {})
      EasyExtensions::IMAP.new(imap_options, options).available_folders
    end

    def self.check(imap_options = {}, options = {})
      EasyExtensions::IMAP.new(imap_options, options).check
    end

    def self.logger
      @logger ||= Logger.new(File.join(Rails.root, 'log', 'imap.log'))
    end

    attr_reader :imap_options, :options, :host, :port, :folders, :ssl, :starttls, :verify

    def initialize(imap_options = {}, options = {})
      @imap_options = imap_options
      @options      = options

      @host = imap_options[:host] || '127.0.0.1'
      @port = imap_options[:port] || '143'

      @folders = get_folder_from_imap_options

      @ssl      = !imap_options[:ssl].nil?
      @starttls = !imap_options[:starttls].nil?
      @verify   = imap_options[:dont_verify_server_cert].nil?
    end

    def imap
      @imap ||= Net::IMAP.new(host, port, ssl, nil, @verify)
    end

    def test_connection
      login!
      folders.each { |folder| imap.select(folder) }
      logout!

      true
    end

    def available_folders
      login!
      list = imap.list('', '*')
      imap.logout
      imap.disconnect
      list
    end

    def check
      @all_ok = true

      if logger
        options[:logger] = logger
        logger.info "#{Time.now} #{mail_handler_klass.name} Connecting to #{host} - #{username}..."
      end

      login!
      folders.each { |folder| check_folder(folder) }
      logout!

      @all_ok
    end

    def check_folder(folder)
      imap.select(folder)
      imap.uid_search(['NOT', 'SEEN']).each do |uid|
        msg = imap.uid_fetch(uid, 'RFC822')[0].attr['RFC822']
        att = nil
        logger.info "#{Time.now} #{mail_handler_klass.name} Receiving message #{uid}" if logger

        if easy_rake_task
          options[:easy_rake_task_info_detail] = prepare_info_detail(easy_rake_task)
          easy_rake_task_info_detail           = options[:easy_rake_task_info_detail]
          att                                  = save_message_to_attachments(easy_rake_task, msg, uid)
        end

        status        = EasyRakeTaskInfoDetailReceiveMail::STATUS_UNKNOWN
        status_detail = nil

        begin
          mail_processed = mail_handler_klass.receive(msg, options)
        rescue StandardError => e
          mail_processed = false
          status_detail  = Redmine::CodesetUtil.replace_invalid_utf8(e.message.to_s.dup)
          logger.error "#{Time.now} #{mail_handler_klass.name} Message #{uid} exception: #{e.message}\n#{e.backtrace}" if logger
        end

        case mail_processed
        when EasyMailHandler::STATUS_SUCCESSFUL
          logger.info "#{Time.now} #{mail_handler_klass.name} Message #{uid} was ignored" if logger
          imap.uid_store(uid, "+FLAGS", [:Seen])
          status = EasyRakeTaskInfoDetailReceiveMail::STATUS_RECEIVED
        when EasyMailHandler::STATUS_ERROR, false
          logger.info "#{Time.now} #{mail_handler_klass.name} Message #{uid} can not be processed" if logger
          @all_ok = false
          imap.uid_store(uid, "+FLAGS", [:Seen])
          move(uid, imap_options[:move_on_failure])

          status = EasyRakeTaskInfoDetailReceiveMail::STATUS_CANNOT_BE_PROCESSED
        else
          logger.info "#{Time.now} #{mail_handler_klass.name} Message #{uid} successfully received" if logger
          move(uid, imap_options[:move_on_success])
          imap.uid_store(uid, "+FLAGS", [:Seen, :Deleted])

          status = EasyRakeTaskInfoDetailReceiveMail::STATUS_RECEIVED
        end

        if easy_rake_task_info_detail
          easy_rake_task_info_detail.status    = status
          easy_rake_task_info_detail.reference = att
          easy_rake_task_info_detail.detail    = status_detail if status_detail
          easy_rake_task_info_detail.save
        end

      end
    end

    private

    def prepare_info_detail(easy_rake_task)
      if easy_rake_task.current_easy_rake_task_info
        easy_rake_task_info_detail      = easy_rake_task.current_easy_rake_task_info.easy_rake_task_info_details.build
        easy_rake_task_info_detail.type = 'EasyRakeTaskInfoDetailReceiveMail'
        easy_rake_task_info_detail.save
        easy_rake_task_info_detail
      end
    end

    def save_message_to_attachments(easy_rake_task, msg, uid)
      message_subject       = Redmine::CodesetUtil.replace_invalid_utf8((msg =~ /^Subject: (.*)/ ? $1 : '').strip)
      message_disk_filename = Attachment.disk_filename(Attachment.sanitize_filename(message_subject + '.eml'))
      message_disk_filename = message_disk_filename.split('_')
      att                   = Attachment.where(:container_type => 'EasyRakeTask').where(["#{Attachment.table_name}.disk_filename LIKE ?", "%#{message_disk_filename.last}"]).first
      att                   ||= EasyUtils::FileUtils.save_and_attach_email_message(msg, uid, easy_rake_task, message_subject, User.current)
    end

    def move(uid, target)
      imap.uid_copy(uid, target.b) if target
    end

    def login!
      imap.starttls if starttls
      imap.login(username, password) unless username.nil?
    end

    def logout!
      imap.expunge
      imap.logout
      imap.disconnect
    end

    def get_folder_from_imap_options
      _folders = (imap_options[:folder] || imap_options[:folders])

      case _folders
      when String
        _folders.split(/[\r\n]+/)
      when Array
        _folders
      else
        # NilClass or unknown
        # TODO: raise if unknown?
        ['INBOX']
      end
    end

    def mail_handler_klass
      @mail_handler_klass ||= (options[:mail_handler_klass] || 'EasyIssueMailHandler').constantize
    end

    def logger
      options[:logger] || self.class.logger
    end

    def username
      imap_options[:username]
    end

    def password
      imap_options[:password]
    end

    def easy_rake_task
      options[:easy_rake_task]
    end

  end
end
