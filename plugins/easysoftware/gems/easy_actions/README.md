# EasyActions

<!--
  -- Replace for true repository location
  --
[![coverage report](https://git.easy.cz/platform-2.0/features/easy_actions/badges/master/coverage.svg)](https://git.easy.cz/platform-2.0/features/easy_actions/commits/master)
  --
-->

## How to install

Add to your Gemfile or gems.rb

```ruby
# From gems server
source 'https://gems.easysoftware.com' do
  gem 'easy_actions'
end

# From git server
gem 'easy_actions', git: 'git@git.easy.cz:gems/easy_actions', branch: 'master'
```

## Development

Please follow our [Guidelines](https://git.easy.cz/external/guidelines/wikis/home)

For full feature list of RYS see [RYS wiki](https://github.com/easysoftware/rys/wiki)

### 1) From the platform gemfile

1. Open gemfile (e.g: APP_ROOT/Gemfile.local)
2. Add `gem 'easy_actions', path: GENERATED_RYS_LOCATION`
3. Run `bundle install`
4. Run the server and develop

### 2) Link to redmine plugin

1. Make a symlink into `plugins/easysoftware/local`
2. Run `bundle install`
3. Run the server and develop

### 3) From generated rys itself

1. Symlink the platform (dummy app) into `test/dummy`
2. Run `bundle install`
3. Run the server and develop
