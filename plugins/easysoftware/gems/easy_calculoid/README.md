# EasyCalculoid

<!--
  -- Replace for true repository location
  --
[![coverage report](https://git.easy.cz/platform-2.0/features/easy_calculoid/badges/master/coverage.svg)](https://git.easy.cz/platform-2.0/features/easy_calculoid/commits/master)
  --
-->

## How to install

Add to your Gemfile or gems.rb

```ruby
# From gems server
source 'https://gems.easysoftware.com' do
  gem 'easy_calculoid'
end

# From git server
gem 'easy_calculoid', git: 'git@git.easy.cz:gems/easy_calculoid', branch: 'master'
```

## Development

Please follow our [Guidelines](https://git.easy.cz/external/guidelines/wikis/home)

### 1) From the platform gemfile

1. Open gemfile (e.g: APP_ROOT/Gemfile.local)
2. Add `gem 'easy_calculoid', path: GENERATED_RYS_LOCATION`
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
