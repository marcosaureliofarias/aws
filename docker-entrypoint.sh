#!/bin/bash -l
set -e

case "$1" in
  "install")
    bundle exec rake db:migrate
    bundle exec rake easyproject:install RAILS_ENV=production
    ;;
  "server" | "start")
    export RAILS_LOG_TO_STDOUT=1
    bundle exec puma --dir "${RAILS_DIR}" -e production -p 3000 -C "${RAILS_DIR}/config/easy_puma.rb"
    ;;
  "sidekiq")
    bundle exec sidekiq -e production
    ;;
  "cron" | "run_tasks")
    bundle exec rake easyproject:scheduler:run_tasks RAILS_ENV=production
    ;;
  *)
    echo "Unknown action. Use install, server of sidekiq."
    exit 1
    ;;
esac
