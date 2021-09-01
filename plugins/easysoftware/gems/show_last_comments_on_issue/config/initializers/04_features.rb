# This file define all features
#
# Rys::Feature.add('show_last_comments_on_issue.project.show')
# Rys::Feature.add('show_last_comments_on_issue.issue.show')
# Rys::Feature.add('show_last_comments_on_issue.time_entries.show')

Rys::Feature.add('show_last_comments_on_issue')
Rys::Feature.add('show_last_comments_on_issue.show', default_db_status: Rails.env.test?)
Rys::Feature.add('show_last_comments_on_issue.index')