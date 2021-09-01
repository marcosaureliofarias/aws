# ProjectFlags

## Development

##### By path (default)

Into gem file

    gem 'project_flags', path: PLUGIN_PATH


##### By git

Into gem file

    gem 'project_flags', git: 'git@git.cz:plugins/project_flags.git'

Into shell

    bundle config local.project_flags PLUGIN_PATH


##### By redmine plugin

Ensure you have redmine plugin for rys plugins

    rails generate rys:redmine:plugin REDMINE_PLUGIN

Move plugin

    mv PLUGIN_PATH REDMINE_PLUGIN/local
