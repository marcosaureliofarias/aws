# ShowLastCommentsOnIssue

## Development

##### By path (default)

Into gem file

    gem 'show_last_comments_on_issue', path: PLUGIN_PATH


##### By git

Into gem file

    gem 'show_last_comments_on_issue', git: 'git@git.cz:plugins/show_last_comments_on_issue.git'

Into shell

    bundle config local.show_last_comments_on_issue PLUGIN_PATH


##### By redmine plugin

Ensure you have redmine plugin for rys plugins

    rails generate rys:redmine:plugin REDMINE_PLUGIN

Move plugin

    mv PLUGIN_PATH REDMINE_PLUGIN/local
