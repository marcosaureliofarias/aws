#!/bin/bash -l
set -e
source /etc/profile

pushd "${RAILS_DIR}"

function install_db_server() {
  if [[ "${DB}" == "mysql" ]]; then
    apt-get install -y wget lsb-release gnupg

    export DEBIAN_FRONTEND=noninteractive
    debconf-set-selections <<< "mysql-apt-config mysql-apt-config/select-server select mysql-8.0"
    debconf-set-selections <<< "mysql-apt-config mysql-apt-config/select-product select Apply"

    pushd /tmp
      wget https://dev.mysql.com/get/mysql-apt-config_0.8.15-1_all.deb
      dpkg -i mysql-apt-config_0.8.15-1_all.deb
      apt-get update && apt-get install -y mysql-common libmysqlclient-dev
    popd
  else
    apt-get update && apt-get -y install --no-install-recommends default-libmysqlclient-dev
  fi
}

function create_database_yml() {
  cat >./config/database.yml <<EOF
production: &production
  adapter: mysql2
  host: <%= ENV["DB_HOST"] || "host.docker.internal" %>
  port: <%= ENV["DB_PORT"] || 3306 %>
  database: <%= ENV["MYSQL_DATABASE"] %>
  username: <%= ENV["MYSQL_USER"] || "root" %>
  password: <%= ENV["MYSQL_PASSWORD"] || ENV["MYSQL_ROOT_PASSWORD"] %>
  encoding: utf8mb4
development:
  <<: *production
test:
  <<: *production
  database: <%= ENV["DB_NAME"] %>_test
EOF
}

function create_configuration_yml() {
  cat >./config/configuration.yml <<EOF
default:
 email_delivery:
   delivery_method: :smtp
   smtp_settings:
     address: <%= ENV["SMTP_HOST"] || "host.docker.internal" %>
     port: <%= ENV["SMTP_PORT"] || 25 %>
     authentication: <%= ENV["SMTP_AUTHENTICATION"] || :none %>
     user_name: <%= ENV["SMTP_USER_NAME"] %>
     domain: <%= ENV["SMTP_DOMAIN"] %>
     password:  <%= ENV["SMTP_PASSWORD"] %>
     tls: <%= ENV["SMTP_TLS"] || false %>
     enable_starttls_auto: <%= ENV["SMTP_ENABLE_STARTTLS_AUTO"] || false %>
     openssl_verify_mode: <%= ENV["SMTP_OPENSSL_VERIFY_MODE"] || "NONE" %>
EOF
}
function create_secret_token() {
  NEW_UUID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
  #   date | md5sum | tr -d " "
  cat >./config/initializers/secret_token.rb <<EOF
RedmineApp::Application.config.secret_key_base = "#{ENV['SECRET_KEY_BASE'] || "${NEW_UUID}"}"
EOF
}
function create_sidekiq_configuration() {
  cat >./config/additional_environment.rb <<EOF
config.active_job.queue_adapter = :sidekiq
Sidekiq.configure_server do |config|
  config.redis = { url: "redis://#{ENV["REDIS_HOST"]}:#{ENV["REDIS_PORT"] || 6379}/1" }
end
Sidekiq.configure_client do |config|
  config.redis = { url: "redis://#{ENV["REDIS_HOST"]}:#{ENV["REDIS_PORT"] || 6379}/1" }
end
EOF
}

# install Oracle mysql or mariadb (default) based on request
install_db_server

# move files to mountpoint
for d in log files public git_repositores; do
  if [[ -s ${RAILS_DIR}/$d ]]; then
    rsync -avh ${RAILS_DIR}/$d/ ${HOME}/$d/
    rm -rf ${RAILS_DIR}/$d
    ln -s ${HOME}/$d ${RAILS_DIR}/$d
  fi
done

if [[ ! -s ./config/database.yml ]]; then
  create_database_yml
fi

if [[ ! -s ./config/configuration.yml ]]; then
  create_configuration_yml
fi

if [[ ! -s ./config/initializers/secret_token.rb ]]; then
  create_secret_token
fi

if [[ ! -s ./config/additional_environment.rb ]]; then
  create_sidekiq_configuration
fi
