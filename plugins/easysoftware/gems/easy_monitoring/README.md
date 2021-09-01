# EasyMonitoring

## Development

Add gem to Gemfile

```ruby
source 'https://gems.easysoftware.com' do
  gem 'easy_monitoring', '~> 0.2.1'
end
```

Add to routes (file config/routes.rb)
```ruby
mount EasyMonitoring::Engine, at: "/"
```

Add new initializer file
```ruby
EasyMonitoring::Metadata.configure do |metadata|
  metadata.host_name = 'your.site.domain'
  # you can also add more metadata like version or whatever
  # metadata.version = '1.2.3'
  # metadata.weather = 'Always sunny'
end
```