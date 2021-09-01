# SecurityUserLock

## Development

##### By path (default)

Into gem file

    gem 'security_user_lock', path: PLUGIN_PATH


##### By git

Into gem file

    gem 'security_user_lock', git: 'git@git.cz:plugins/security_user_lock.git'

Into shell

    bundle config local.security_user_lock PLUGIN_PATH


##### By redmine plugin

Ensure you have redmine plugin for rys plugins

    rails generate rys:redmine:plugin REDMINE_PLUGIN

Move plugin

    mv PLUGIN_PATH REDMINE_PLUGIN/local
