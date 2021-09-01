module EasyPatch
  module MailerPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        helper :easy_journal
        helper :entity_attribute

        alias_method_chain :issue_add, :easy_extensions
        alias_method_chain :issue_edit, :easy_extensions
        alias_method_chain :news_added, :easy_extensions
        alias_method_chain :document_added, :easy_extensions
        alias_method_chain :test_email, :easy_extensions
        alias_method_chain :attachments_added, :easy_extensions
        alias_method_chain :mail, :easy_extensions

        class << self

          alias_method_chain :deliver_attachments_added, :easy_extensions
          alias_method_chain :deliver_document_added, :easy_extensions
          alias_method_chain :deliver_issue_add, :easy_extensions
          alias_method_chain :deliver_issue_edit, :easy_extensions
          alias_method_chain :deliver_news_added, :easy_extensions
          alias_method_chain :deliver_news_comment_added, :easy_extensions
          alias_method_chain :deliver_message_posted, :easy_extensions

        end

        def get_mail_subject_for_issue_add(issue, user)
          if EasySetting.value(:issue_mail_subject_style) == 'redmine'
            s = "[#{issue.project.name} - #{issue.tracker.name}"
            s << " ##{issue.id}" if EasySetting.value('show_issue_id', issue.project)
            s << "] (#{issue.status.name}) #{issue.subject}"
          else
            l((user == issue.assigned_to ? :'mail.subject.my_issue_add' : :'mail.subject.issue_add'),
              :issuestatus  => issue.status.name,
              :issuesubject => (EasySetting.value('show_issue_id', issue.project) ? "##{issue.id} - #{issue.subject}" : issue.subject),
              :projectname  => issue.project.family_name(:separator => ' > '),
              :issueid      => issue.id,
              :tasksubtask  => label_tasksubtask(issue))
          end
        end

        def get_mail_subject_for_issue_edit(issue, journal, user)
          if EasySetting.value(:issue_mail_subject_style) == 'redmine'
            s = "[#{issue.project.name} - #{issue.tracker.name}"
            s << " ##{issue.id}" if EasySetting.value('show_issue_id', issue.project)
            s << '] '
            s << "(#{issue.status.name}) " if journal.new_value_for('status_id')
            s << issue.subject
            s
          else
            l((user == issue.assigned_to ? :'mail.subject.my_issue_edit' : :'mail.subject.issue_edit'),
              :issuestatus  => issue.status.name,
              :issuesubject => (EasySetting.value('show_issue_id', issue.project) ? "##{issue.id} - #{issue.subject}" : issue.subject),
              :projectname  => issue.project.family_name(:separator => ' > '),
              :issueid      => issue.id,
              :tasksubtask  => label_tasksubtask(issue))
          end
        end

        def get_mail_subject_for_news_add(news)
          l(:'mail.subject.news_added', :newstitle => news.title, :projectname => news.project.family_name(:separator => ' > '))
        end

        def get_mail_subject_for_document_add(document)
          l(:'mail.subject.document_added', :documenttitle => document.title, :projectname => document.project.family_name(:separator => ' > '))
        end

        def label_tasksubtask(issue)
          label = issue.parent_id ? l(:label_subtask) : l(:label_issue)
          if (User.current.language.presence || ::I18n.locale.to_s) == 'de'
            label
          else
            label.downcase
          end
        end
      end
    end

    module ClassMethods
      def inline_css_file_path
        assets_path = Redmine::Plugin.find(:easy_extensions).assets_directory
        File.join(assets_path, 'stylesheets', 'mailer', '_mailer_inline.css')
      end

      def non_inline_css_file_path
        assets_path = Redmine::Plugin.find(:easy_extensions).assets_directory
        File.join(assets_path, 'stylesheets', 'mailer', '_mailer_non_inline.css')
      end

      def deliver_attachments_added_with_easy_extensions(attachments)
        container = attachments.first.container
        return if !container || !container.project || container.project.is_planned
        case container.class.name
        when 'Project', 'Version'
          users = container.project.notified_users.select { |user| user.allowed_to?(:view_files, container.project) }
        when 'Document'
          users = container.recipients
        end

        users.each do |user|
          attachments_added(user, attachments).deliver_later
        end
      end

      def deliver_document_added_with_easy_extensions(document, author)
        return if document.project.is_planned

        deliver_document_added_without_easy_extensions(document, author)
      end

      def deliver_news_added_with_easy_extensions(news)
        return if news.project.is_planned

        deliver_news_added_without_easy_extensions(news)
      end

      def deliver_news_comment_added_with_easy_extensions(comment)
        return if comment.commented.project.is_planned

        deliver_news_comment_added_without_easy_extensions(comment)
      end

      def deliver_message_posted_with_easy_extensions(message)
        return if message.project.is_planned

        deliver_message_posted_without_easy_extensions(message)
      end

      def deliver_issue_add_with_easy_extensions(issue)
        return if issue.project && (issue.project.easy_is_easy_template? || issue.project.is_planned)

        issue.get_notified_users_for_issue_new.each do |user|
          issue_add(user, issue).deliver_later
        end
      end

      def deliver_issue_edit_with_easy_extensions(journal)
        issue = journal.journalized
        return if issue.project && (issue.project.easy_is_easy_template? || issue.project.is_planned)

        issue.get_notified_users_for_issue_edit(journal).each do |user|
          issue_edit(user, journal).deliver_later
        end
      end
    end

    module InstanceMethods

      def issue_add_with_easy_extensions(user, issue)
        return if issue.project && (issue.project.easy_is_easy_template? || issue.project.is_planned)
        redmine_headers 'Project'  => issue.project.identifier,
                        'Issue-Id' => issue.id
        redmine_headers 'Issue-Tracker' => issue.tracker.name if issue.tracker
        redmine_headers 'Issue-Author' => issue.author.login if issue.author
        redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
        message_id issue
        references issue

        @author    = issue.author # redmine inner logic in "mail" function
        @issue     = issue
        @issue_url = issue_url(issue)
        @user      = user

        mail :to      => user,
             :subject => get_mail_subject_for_issue_add(issue, user)
      end

      def issue_edit_with_easy_extensions(user, journal)
        issue = journal.journalized
        redmine_headers 'Project'  => issue.project.identifier,
                        'Issue-Id' => issue.id
        redmine_headers 'Issue-Tracker' => issue.tracker.name if issue.tracker
        redmine_headers 'Issue-Author' => issue.author.login if issue.author
        redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
        message_id journal
        references issue

        @user            = user
        @author          = journal.user # redmine inner logic in "mail" function
        @issue           = issue
        @journal         = journal
        @journal_details = journal.visible_details
        @issue_url       = issue_url(issue, :anchor => "change-#{journal.id}")

        mail :to      => user,
             :subject => get_mail_subject_for_issue_edit(issue, journal, user)
      end

      def news_added_with_easy_extensions(user, news)
        redmine_headers 'Project' => news.project.identifier
        message_id news
        references news

        @author   = news.author # redmine inner logic in "mail" function
        @news     = news
        @news_url = url_for(:controller => 'news', :action => 'show', :id => news)

        mail :to      => user,
             :subject => get_mail_subject_for_news_add(news)
      end

      def document_added_with_easy_extensions(user, document, author)
        redmine_headers 'Project' => document.project.identifier
        @author       = author
        @document     = document
        @document_url = url_for(:controller => 'documents', :action => 'show', :id => document)

        mail :to => user, :subject => get_mail_subject_for_document_add(document)
      end

      def test_email_with_easy_extensions(user)
        @url       = home_url
        @app_name  = EasyExtensions::EasyProjectSettings.app_name
        @app_url   = EasyExtensions::EasyProjectSettings.app_link
        @app_url   = "http://#{@app_url}" unless /^http(s)?:\/\//.match?(@app_url)
        @app_email = EasyExtensions::EasyProjectSettings.app_email

        mail :to      => user,
             :subject => "#{@app_name} test"
      end

      def attachments_added_with_easy_extensions(user, attachments)
        container = attachments.first.container
        return if !container || !container.project || container.project.is_planned
        added_to     = ''
        added_to_url = ''
        @author      = attachments.first.author
        case container.class.name
        when 'Project'
          added_to_url = url_for(:controller => 'files', :action => 'index', :project_id => container)
          added_to     = "#{l(:label_project)}: #{container}"
        when 'Version'
          added_to_url = url_for(:controller => 'files', :action => 'index', :project_id => container.project)
          added_to     = "#{l(:label_version)}: #{container.name}"
        when 'Document'
          added_to_url = url_for(:controller => 'documents', :action => 'show', :id => container.id)
          added_to     = "#{l(:label_document)}: #{container.title}"
        end
        redmine_headers 'Project' => container.project.identifier
        @attachments  = attachments
        @added_to     = added_to
        @added_to_url = added_to_url
        mail :to      => user,
             :subject => "[#{container.project.family_name(:separator => ' > ')}] #{l(:label_attachment_new)}"
      end

      # issue #323334
      # EasyRedmine primary set sender from setting. Without author name.
      # Author name in sender create mess in Outlook.
      def mail_with_easy_extensions(headers={}, &block)
        headers.reverse_merge!('From' => Setting.mail_from)
        mail_without_easy_extensions(headers, &block)
      end

    end
  end
end
EasyExtensions::PatchManager.register_model_patch 'Mailer', 'EasyPatch::MailerPatch'
