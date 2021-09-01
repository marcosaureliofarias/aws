class IssueInvitationObserverMailer < ActionMailer::Base

  def invitation(issue, invitation)
    from = Setting.mail_from

    headers['X-Mailer']                 = 'Redmine'
    headers['X-Redmine-Host']           = Setting.host_name
    headers['X-Redmine-Site']           = Setting.app_title
    headers['X-Auto-Response-Suppress'] = 'OOF'
    headers['Auto-Submitted']           = 'auto-generated'
    headers['From']                     = from
    headers['List-Id']                  = "<#{from.to_s.tr('@', '.')}>"
    headers['Content-Type']             = 'text/calendar; charset=UTF-8'

    sbj         = "#{issue.author.name}: #{issue.subject} (##{issue.id})"
    @invitation = invitation

    mail(:to => issue.recipients, :subject => sbj) do |format|
      format.ics {
        render :plain => invitation, :layout => false
      }
    end

  end

end
