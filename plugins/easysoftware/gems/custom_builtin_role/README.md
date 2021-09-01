# CustomBuiltinRole

Adds the ability to assign a custom builtin role per a user type. Implements a new select box on the user type settings page.

This custom role replaces the default "non-member" role when the user applies for a permission in the project not being a member of the project.

So the user's privileges in the project are defined not by the default "non-member" role, but by the custom role assigned in the settings of the user type.

Beware! the custom role, if set, applies to all the projects for all the users of the specific user type. So you better check the role privileges twice before setting it as a builtin role.

The list of users who have privileges in the project based on the usual membership, but on the builtin role feature, is available in Project > Settings > Members.

<!--
  -- Replace for true repository location
  --
[![coverage report](https://git.easy.cz/platform-2.0/features/custom_builtin_role/badges/master/coverage.svg)](https://git.easy.cz/platform-2.0/features/custom_builtin_role/commits/master)
  --
-->

## How to install

Add to your Gemfile or gems.rb

```ruby
# From gems server
source 'https://gems.easysoftware.com' do
  gem 'custom_builtin_role'
end

# From git server
gem 'custom_builtin_role', git: 'git@git.easy.cz:gems/custom_builtin_role', branch: 'master'
```

## Development

Please follow our [Guidelines](https://git.easy.cz/external/guidelines/wikis/home)

For full feature list of RYS see [RYS wiki](https://github.com/easysoftware/rys/wiki)

### 1) From the platform gemfile

1. Open gemfile (e.g: APP_ROOT/Gemfile.local)
2. Add `gem 'custom_builtin_role', path: GENERATED_RYS_LOCATION`
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
