# DependentListCustomField

## Development

##### By path (default)

Into gem file

    gem 'dependent_list_custom_field', path: PLUGIN_PATH


##### By git

Into gem file

    gem 'dependent_list_custom_field', git: 'git@git.cz:plugins/dependent_list_custom_field.git'

Into shell

    bundle config local.dependent_list_custom_field PLUGIN_PATH


##### By redmine plugin

Ensure you have redmine plugin for rys plugins

    rails generate rys:redmine:plugin REDMINE_PLUGIN

Move plugin

    mv PLUGIN_PATH REDMINE_PLUGIN/local
