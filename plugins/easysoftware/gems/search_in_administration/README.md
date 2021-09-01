# SearchInAdministration

## Development

##### By path (default)

Into gem file

    gem 'search_in_administration', path: PLUGIN_PATH


##### By git

Into gem file

    gem 'search_in_administration', git: 'git@git.cz:plugins/search_in_administration.git'

Into shell

    bundle config local.search_in_administration PLUGIN_PATH


##### By redmine plugin

Ensure you have redmine plugin for rys plugins

    rails generate rys:redmine:plugin REDMINE_PLUGIN

Move plugin

    mv PLUGIN_PATH REDMINE_PLUGIN/local
