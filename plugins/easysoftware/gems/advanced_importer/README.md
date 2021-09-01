# AdvancedImporter
[![pipeline status](https://git.easy.cz/platform-2.0/features/advanced_importer/badges/master/pipeline.svg)](https://git.easy.cz/platform-2.0/features/advanced_importer/commits/master)
[![coverage report](https://git.easy.cz/platform-2.0/features/advanced_importer/badges/master/coverage.svg)](https://git.easy.cz/platform-2.0/features/advanced_importer/commits/master)

Add ability to import CSV or XML data to Easy.

currently supported entities are:

* users
* issues
* projects
* easy_contacts

Advanced Importer also brings complex import from:

* Jira
* Asana

## Key features

* import any CSV in UTF-8
* support only CSV (Comma Separated Value)
* choose template of project when import project
* XML use xsl transformation to standard XML import 

## Setup
In your `Gemfile`:
```ruby
source 'https://gems.easysoftware.com' do
  gem 'advanced_importer', '~> 1.2.4'
end
```
then run `bundle install`

### Additional configuration

You can register your own importer by extend `available_import_entities` config

In your initializer, example: 

```ruby
AdvancedImporter.config.available_import_entities << 'EasyEntityImports::EasyContactCsvImport'
```


## Development

##### By path (default)

Into gem file

    gem 'advanced_importer', path: PLUGIN_PATH


##### By git

Into gem file

    gem 'advanced_importer', git: 'git@git.cz:plugins/advanced_importer.git'

Into shell

    bundle config local.advanced_importer PLUGIN_PATH


##### By redmine plugin

Ensure you have redmine plugin for rys plugins

    rails generate rys:redmine:plugin REDMINE_PLUGIN

Move plugin

    mv PLUGIN_PATH REDMINE_PLUGIN/local
