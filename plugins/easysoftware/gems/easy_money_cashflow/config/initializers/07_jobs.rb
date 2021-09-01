# ActiveJob basics
#   https://guides.rubyonrails.org/active_job_basics.html
#
# Sidekiq home page
#   https://github.com/mperham/sidekiq
#
# Sidekiq::Cron home page
#   https://github.com/ondrejbartas/sidekiq-cron
#
# Parsing cron
#   https://github.com/floraison/fugit
#
# Easy implementation of cron jobs
#   {EasyRakeTask}

# Set one-shot job
# EasyMoneyCashflow::MyJob.perform_later(1, 2, 3)
#
# Set repeating job
# EasyMoneyCashflow::MyJob.repeat('every 5 minutes').perform_later(4, 5, 6)
