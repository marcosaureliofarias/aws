# EasyZapier

## Development

##### By path (default)

Into gem file

    gem 'easy_zapier', path: PLUGIN_PATH


##### By git

Into gem file

    gem 'easy_zapier', git: 'git@git.cz:plugins/easy_zapier.git'

Into shell

    bundle config local.easy_zapier PLUGIN_PATH


##### By redmine plugin

Ensure you have redmine plugin for rys plugins

    rails generate rys:redmine:plugin REDMINE_PLUGIN

Move plugin

    mv PLUGIN_PATH REDMINE_PLUGIN/local
