# EasyJob

Asynchronous job for Redmine, EasyRedmine and EasyProject.

## Usage

### Delay jobs

Every methods called after `.easy_delay` will be delayed and executed on other thread. This method could be used for any ruby Object.

```ruby
# Reschedule first issue to today
Issue.first.easy_delay.reschedule_on(Date.today)

# Save ORM object with lot of callbacks
[Issue.new, Issue.new].map { |i| i.easy_delay.save }
```

### Mailer jobs

Deliver email later.

```ruby
# Generating and sending will be done later
Mailer.issue_add(issue, ['test@example.net'], []).easy_deliver

# Email is generated now but send later
Mailer.issue_add(issue, ['test@example.net'], []).easy_safe_deliver
```

### Custom jobs

You can also create custom task with own exceptions capturing.

Job can be started with 3 calling:

- `.perform_async(*args)` started when pool cointains free worker
- `.perform_later(*args)` in production call perform_async, otherwise perform_now
- `.perform_now(*args)` stared in current thread (synced)
- `.perform_in(*args, interval:)` job is added to queue after interval second
- `.perform_every(*args, interval:, timeout:, start_at:)` job is executed every interval second
  - **interval:** seconds between task executions (required)
  - **timeout:** max seconds for running (optional)
  - **start_at:** time of first execution (optional)

```ruby
class PDFJob < EasyJob::Task

  include IssuesHelper

  def perform(issue_ids, project_id)
    issues = Issue.where(id: issue_ids)
    project = Project.find(project_id)
    query = IssueQuery.new

    result = issues_to_pdf(issues, project, query)

    path = Rails.root.join('public', 'issues.pdf')
    File.open(path, 'wb') {|f| f.write(result) }
  end

end

PDFJob.perform_async(Issue.ids, Project.first.id)
```

### ActiveJob

First you need to set ActiveJob adapter. For example at application.rb

```ruby
config.active_job.queue_adapter = :easy_job
```

Next you can use it as every ActiveJob.

```ruby
class MyJob < ActiveJob::Base

  def perform
    puts "Ondra"
  end

end

MyJob.perform_later
MyJob.set(wait: 10.seconds).perform_later
```

### Process Mutex

If you want synchronize access across process you can use `EasyJob::SharedMutex`.

```ruby
class MyJob < EasyJob::Task

  def perform
    mutex = EasyJob::SharedMutex.new('myjob_mutex')
    mutex.synchronize {
      puts "Only pid=#{Process.pid} is in critical section"
      sleep 5
      puts "Now pid=#{Process.pid} leave critical section"
    }
  end

end

MyJob.perform_async
```

### Tenant

If you are using tenant you can simply use:

```ruby
require 'easy_job/tenant'
```

### Exceptions notifier

If you are using easy exception notifier you can use:

```ruby
require 'easy_job/exceptions_notifier'
```
