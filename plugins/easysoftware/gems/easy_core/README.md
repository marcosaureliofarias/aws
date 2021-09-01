# EasyCore

The core plugin for all rys plugins.

First make sure that this plugin is present in application gem file or in depencies file.

## Testing

> Rys plugins comes with new spec_helper because that from easyproject
> is is terribly confusing.

You can test in many ways.

Let's assume you have a plugin called `easy` and plugin is present in gem file.

### From Rails application

1. Run test just for easy

   ```bash
   bundle exec rake easy:spec
   ```

2. Run all rys plugins

   ```bash
   bundle exec rake easy_core:spec:all
   ```

### Directly from plugin directory

It this way you need to have some dummy application.

- Can specified via environment variable `DUMMY_PATH`
- Or put it into `test/dummy` directory


1. Run test just for easy

   ```bash
   # simly
   bundle exec rspec

   # or with rake
   bundle exec rake ondra:spec

   # or selectively
   bundle exec rspec PATH_TO_FILE_OR_DIRECTORY
   ```

2. Run all rys plugins

   ```bash
   bundle exec rake easy_core:spec:all
   ```
