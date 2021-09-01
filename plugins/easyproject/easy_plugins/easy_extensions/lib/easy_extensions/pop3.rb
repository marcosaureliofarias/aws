require 'net/pop'

module EasyExtensions
  module POP3

    class << self

      def enable_pop_ssl(pop_options)
        if pop_options[:dont_verify_server_cert]
          Net::POP3.enable_ssl(OpenSSL::SSL::VERIFY_NONE)
        else
          Net::POP3.enable_ssl(OpenSSL::SSL::VERIFY_PEER)
        end
      end

      def test_connection(pop_options = {})
        enable_pop_ssl(pop_options) if pop_options[:ssl]
        host = pop_options[:host] || '127.0.0.1'
        port = pop_options[:port] || (pop_options[:ssl] ? '995' : '110')
        apop = (pop_options[:apop].to_s == '1')
        pop  = Net::POP3.APOP(apop).new(host, port)

        pop.start(pop_options[:username], pop_options[:password]) do |pop_session|
        end

        true
      end

      def check(pop_options = {}, options = {})
        enable_pop_ssl(pop_options) if pop_options[:ssl]
        host               = pop_options[:host] || '127.0.0.1'
        port               = pop_options[:port] || (pop_options[:ssl] ? '995' : '110')
        apop               = (pop_options[:apop].to_s == '1')
        delete_unprocessed = (pop_options[:delete_unprocessed].to_s == '1')
        easy_rake_task     = options[:easy_rake_task]
        mail_handler_klass = (options[:mail_handler_klass] || 'EasyIssueMailHandler').constantize

        all_ok           = true
        options[:logger] = logger if logger

        pop = Net::POP3.APOP(apop).new(host, port)
        logger.info "#{Time.now} #{mail_handler_klass.name} Connecting to #{host} - #{pop_options[:username]}..." if logger

        pop.start(pop_options[:username], pop_options[:password]) do |pop_session|
          all_ok = true

          if pop_session.mails.empty?
            logger.info "#{Time.now} #{mail_handler_klass.name} No email to process" if logger
          else
            logger.info "#{Time.now} #{mail_handler_klass.name} #{pop_session.mails.size} email(s) to process..." if logger
            pop_session.each_mail do |msg|
              message    = msg.pop
              message_id = Redmine::CodesetUtil.replace_invalid_utf8((message =~ /^Message-I[dD]: (.*)/ ? $1 : '').strip)
              att        = nil

              if easy_rake_task
                options[:easy_rake_task_info_detail] = prepare_info_detail(easy_rake_task)
                easy_rake_task_info_detail           = options[:easy_rake_task_info_detail]
                att                                  = save_message_to_attachments(easy_rake_task, msg, message_id)
              end

              status        = EasyRakeTaskInfoDetailReceiveMail::STATUS_UNKNOWN
              status_detail = nil

              begin
                mail_processed = mail_handler_klass.receive(message, options)
              rescue StandardError => e
                mail_processed = false
                status_detail  = Redmine::CodesetUtil.replace_invalid_utf8(e.message.to_s.dup)
                logger.error "#{Time.now} #{mail_handler_klass.name} Message #{message_id} exception: #{e.message}\n#{e.backtrace}" if logger
              end

              case mail_processed
              when EasyMailHandler::STATUS_SUCCESSFUL, EasyMailHandler::STATUS_ERROR, false
                if delete_unprocessed
                  msg.delete
                  logger.info "#{Time.now} #{mail_handler_klass.name} Message #{message_id} NOT processed and deleted from the server" if logger
                  status = EasyRakeTaskInfoDetailReceiveMail::STATUS_NOT_PROCESSED_AND_DELETED
                else
                  logger.info "#{Time.now} #{mail_handler_klass.name} Message #{message_id} NOT processed and left on the server" if logger
                  status = EasyRakeTaskInfoDetailReceiveMail::STATUS_NOT_PROCESSED_AND_LEFT_ON_SERVER
                end
                all_ok = false unless EasyMailHandler::STATUS_SUCCESSFUL == mail_processed
              else
                msg.delete
                logger.info "#{Time.now} #{mail_handler_klass.name} Message #{message_id} processed and deleted from the server" if logger

                status = EasyRakeTaskInfoDetailReceiveMail::STATUS_PROCESSED_AND_DELETED
              end

              if easy_rake_task_info_detail
                easy_rake_task_info_detail.status    = status
                easy_rake_task_info_detail.reference = att
                easy_rake_task_info_detail.detail    = status_detail if status_detail
                easy_rake_task_info_detail.save
              end

            end
          end
        end

        all_ok
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

      def logger
        @email_logger ||= Logger.new(File.join(Rails.root, 'log', 'pop3.log'), 'weekly')
      end
    end

  end
end
