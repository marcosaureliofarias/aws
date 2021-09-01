# EasyJenkins

## Development

##### By path (default)

Into gem file

    gem 'easy_jenkins', path: PLUGIN_PATH


##### By git

Into gem file

    gem 'easy_jenkins', git: 'git@git.cz:plugins/easy_jenkins.git'

Into shell

    bundle config local.easy_jenkins PLUGIN_PATH


##### By redmine plugin

Ensure you have redmine plugin for rys plugins

    rails generate rys:redmine:plugin REDMINE_PLUGIN

Move plugin

    mv PLUGIN_PATH REDMINE_PLUGIN/local
