# EasyTwofa

## Development

##### By path (default)

Into gem file

    gem 'easy_twofa', path: PLUGIN_PATH


##### By git

Into gem file

    gem 'easy_twofa', git: 'git@git.cz:plugins/easy_twofa.git'

Into shell

    bundle config local.easy_twofa PLUGIN_PATH


##### By redmine plugin

Ensure you have redmine plugin for rys plugins

    rails generate rys:redmine:plugin REDMINE_PLUGIN

Move plugin

    mv PLUGIN_PATH REDMINE_PLUGIN/local
