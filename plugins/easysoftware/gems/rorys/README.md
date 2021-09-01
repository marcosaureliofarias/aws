# Rorys

An easy way how to maintain one-shot and repeating jobs

For both kind you are using the same class

## Usage

```ruby
source 'https://gems.easysoftware.com' do
  gem 'rorys'
end
```

## One-shot jobs

First, please read https://guides.rubyonrails.org/active_job_basics.html

Properties are determined by choosen adapter `active_job.queue_adapter`

```ruby
class MyJob < Rorys.task

  def perform(*args)
    puts args.join(', ')
  end

end

# Perform as soon as possible
MyJob.perform_later(1, 2, 3)

# Wait 10s
MyJob.set(wait: 10.seconds).perform_later(4, 5, 6)
```

## Repeating jobs

Functionality is the same as with ActiveJob but the jobs are executed by:

1. EasyRakeTask
2. Sidekiq::Cron

However, usage is the same. Cron (repeating options) can be written in two wasy:

- https://github.com/floraison/fugit#fugitcron
- https://github.com/floraison/fugit#fugitnat

The best place where to put repeat definition is `config/initializers` or `after_init.rb`.

```ruby
class MyJob < Rorys.task

  def perform(*args)
    puts args.join(', ')
  end

end

MyJob.repeat('every day at midnight').perform_later(7, 8, 9)
MyJob.repeat('every 5 minutes').perform_later(10, 11, 12)
MyJob.repeat('*/5 * * * *').perform_later(113, 14, 15)
```

## EasyRakeTask

If Sidekiq::Cron is available the EasyRakeTask is maintaned by it

So, in avoid confusion the "process" is

- One-shot tasks are executed by active job adapter
- Repeating jobs are executed by Sidekiq::Cron or EasyRakeTask (in this order)
- EasyRakeTasks are executed by Sidekiq::Cron or EasyRakeTask (in this order)
